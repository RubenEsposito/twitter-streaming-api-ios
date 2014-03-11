//
//  TSTwitterManager.m
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import "TSTwitterManager.h"
#import "TSTweet.h"
#import "TSTwitterParser.h"

@implementation TSTwitterManager

// Initialization of the streaming connection, flags and objects used by the manager
-(void)initManager {
    
    // Initialization of the flag to determine is the stream is running
    _isConnected = NO;
    _isTryingToConnect = NO;
    
    // Start the streaming connection
    [self initStreamingConnectionForPattern:TS_SEARCH_PATTERN];
    
    // Initialize the fetchedResultsController
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    NSLog(@"Tweets count: %lu",(unsigned long)[_fetchedResultsController.fetchedObjects count]);
}



#pragma mark - FetchedResultsController setup


- (NSFetchedResultsController *)fetchedResultsController {
    
    // If we have already created the fetchedresultscontroller, return it
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Create a new fetchedResultsController
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TSTweet" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"id_str" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:_managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}



#pragma mark - Connection setup


- (void)initStreamingConnectionForPattern:(NSString *)aKeyword {
    
    //  Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        
        // OAUth authentication required. The user must accept.
        ACAccountStore *store = [[ACAccountStore alloc] init];
        ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        // Request permission from the user to access the available Twitter accounts
        [store requestAccessToAccountsWithType:twitterAccountType
                                       options:nil
                                    completion:^(BOOL granted, NSError *error) {
                                        
                                        if (error) {
                                            // If the user cant be authenticated, tell the delegate
                                            [self.delegate fetchingTweetsFailedWithError:[error localizedDescription]];
                                        } else {
                                            
                                            if (!granted) {
                                                // If the user denied access, tell the delegate
                                                [self.delegate fetchingTweetsFailedWithError:@"Twitter access denied or no Twitter account available"];
                                            }
                                            else {
                                                
                                                NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
                                                if ([twitterAccounts count] > 0) {
                                                    
                                                    // We take the last account available (we only need it to get access to the API)
                                                    ACAccount *account = [twitterAccounts lastObject];
                                                    
                                                    NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1.1/statuses/filter.json"];
                                                    NSDictionary *params = @{@"track" : aKeyword};
                                                    
                                                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                                            requestMethod:SLRequestMethodPOST
                                                                                                      URL:url
                                                                                               parameters:params];
                                                    
                                                    [request setAccount:account];
                                                    
                                                    // Once we have the authenticated request prepared, we launch the session
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSURLConnection *aConn = [NSURLConnection connectionWithRequest:[request preparedURLRequest] delegate:self];
                                                        [aConn start];
                                                    });
                                                }
                                            }
                                        }
                                    }];
    } else {
        // If there are no twitter accounts, tell the delegate
        [self.delegate fetchingTweetsFailedWithError:@"No Twitter accounts available"];
    }
}


- (BOOL)userHasAccessToTwitter
{
    // If we can create a compose view controller for Twitter then we have access to a Twitter account
    return [SLComposeViewController
            isAvailableForServiceType:SLServiceTypeTwitter];
}



#pragma mark - NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // If we receive the data
    if (data) {
        
        // The stream is running
        _isConnected =  YES;
        
        // Make the delegate aware of being reconnected
        if (_isTryingToConnect) {
            _isTryingToConnect = NO;
            [self.delegate reconnectedToStream];
        }
        
        // Invoke the parser and get the tweet
        NSDictionary *tweet = nil;
        TSTwitterParser *parser = [[TSTwitterParser alloc] init];
        parser.delegate = self;
        tweet = [parser getTweetsFromData:data];
        
        // Save the tweet in Core Data if it contains a coordinate
        NSObject *coordinates = [tweet objectForKey:@"coordinates"];
        if (coordinates != [NSNull null] &&
            [[(NSDictionary *)coordinates objectForKey:@"type"] isEqualToString:@"Point"] &&
            [(NSDictionary *)coordinates objectForKey:@"coordinates"] != [NSNull null]) {
            
            NSError *error;
            NSManagedObjectContext *context = [self managedObjectContext];
            TSTweet *tweetManagedObject = [NSEntityDescription
                                           insertNewObjectForEntityForName:@"TSTweet"
                                           inManagedObjectContext:context];
            tweetManagedObject.id_str = [tweet objectForKey:@"id_str"];
            tweetManagedObject.text = [tweet objectForKey:@"text"];
            tweetManagedObject.lon = [[(NSDictionary *)coordinates objectForKey:@"coordinates"] objectAtIndex:0];
            tweetManagedObject.lat = [[(NSDictionary *)coordinates objectForKey:@"coordinates"] objectAtIndex:1];
            if (![context save:&error]) {
                NSLog(@"Error saving to Core Data: %@", [error localizedDescription]);
            } else {
                
                // Create a timer to delete the tweet in the future
                // It is created in a different thread to avoid the UI disabling the timer
                NSTimer *timer = [NSTimer timerWithTimeInterval:TS_TWEET_TTL
                                                         target:self
                                                       selector:@selector(tweetTimerDidFire:)
                                                       userInfo:@{@"id_str" : [tweet objectForKey:@"id_str"]} repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            }
        }
    }
}

// If the connection fails, try to reconnect in 10 seconds
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    NSLog(@"Connection failed: %@", [error localizedDescription]);
    
    // If the connection fails, tell the delegate
    [self.delegate fetchingTweetsFailedWithError:@"Connection failed. Trying to reconnect."];
    
    // The stream has failed
    _isConnected = NO;
    _isTryingToConnect = YES;
    
    // The stream is closed, so we need to create a new stream from the ground up
    // We wait 5 second to avoid overloading the server
    [self performSelector:@selector(initStreamingConnectionForPattern:) withObject:TS_SEARCH_PATTERN afterDelay:5];
}



#pragma mark - NSFetchedResultsControllerDelegate


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            
            // Called when a new Tweet is inserted in Core Data
            // We call the delegate so it can update its view
            NSLog(@"\n-----------------\nINSERTED: %@\n-----------------\n", anObject);
            [self.delegate insertedNewTweet:(TSTweet *)anObject];
            break;
            
        case NSFetchedResultsChangeDelete:
            
            // Called when a Tweet is deleted in Core Data
            // We call the delegate so it can update its view
            NSLog(@"\n-----------------\nDELETED: %@\n-----------------\n", anObject);
            [self.delegate deletedTweet:(TSTweet *)anObject];
            break;
            
        case NSFetchedResultsChangeUpdate:
            
            break;
            
        case NSFetchedResultsChangeMove:
            
            break;
    }
}



#pragma mark - TSTwitterParserDelegate


- (void)parsingTweetsFailedWithError:(NSError *)error {
    
    // Maybe in other situations it would be a benefit to try to receiver the info and parse again
}



#pragma mark - NSTimer selectors


// The timer associated to a tweet fired and now we must delete it
-(void)tweetTimerDidFire:(NSTimer *)theTimer {
    
    // Get the id from the tweet to delete
    NSString *id_str = [theTimer.userInfo objectForKey:@"id_str"];
    
    // If the stream is up and running, delete the tweet
    if (_isConnected) {
        
        // Look for the tweet in Core Data
        NSError *error;
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        fetch.entity = [NSEntityDescription entityForName:@"TSTweet" inManagedObjectContext:_managedObjectContext];
        fetch.predicate = [NSPredicate predicateWithFormat:@"id_str == %@", id_str];
        NSArray *results = [_managedObjectContext executeFetchRequest:fetch error:&error];
        
        // Delete the Tweet
        for (TSTweet *tweet in results) {
            [_managedObjectContext deleteObject:tweet];
        }
        
    } else {
        
        // If the stream is closed, schedule a new timer so it can be deleted once the connection is restablished
        NSTimer *timer = [NSTimer timerWithTimeInterval:TS_TWEET_TTL
                                                 target:self
                                               selector:@selector(tweetTimerDidFire:)
                                               userInfo:@{@"id_str" : id_str} repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

@end
