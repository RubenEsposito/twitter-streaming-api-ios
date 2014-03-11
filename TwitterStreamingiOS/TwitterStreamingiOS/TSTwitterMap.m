//
//  TSTwitterMap.m
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import "TSTwitterMap.h"
#import "TSMapAnnotation.h"
#import "TSTweet.h"

@interface TSTwitterMap ()

@end

@implementation TSTwitterMap

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Zoom out the map
    [self zoomToWorldAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// It makes the map zoom to show the World view
- (void)zoomToWorldAnimated:(BOOL)animated {
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(MKMapRectWorld);
    [self.theMap setRegion:region animated:animated];
}


#pragma mark - TSTwitterManagerDelegate

-(void)insertedNewTweet:(TSTweet *)tweet {
    
    // When a new tweet arrives, we need to add the annotation for it in the map.
    TSMapAnnotation *tweetAnnotation = [[TSMapAnnotation alloc] init];
    tweetAnnotation.id_str = tweet.id_str;
    tweetAnnotation.text = tweet.text;
    tweetAnnotation.coordinate = CLLocationCoordinate2DMake([tweet.lat doubleValue], [tweet.lon doubleValue]);
    [self.theMap addAnnotation:tweetAnnotation];
}

-(void)deletedTweet:(TSTweet *)tweet {
    
    // When a tweet is deleted, we need to remove it from the map.
    for (TSMapAnnotation *tweetAnnotation in _theMap.annotations) {
        if ([tweetAnnotation.id_str isEqualToString:tweet.id_str]) {
            [self.theMap removeAnnotation:tweetAnnotation];
        }
    }
}

-(void)fetchingTweetsFailedWithError:(NSString *)error {
    
    // When an error with the connection, parsing or anything else occurs, alert the user.
    if (!_theAlert) {
        self.theAlert = [[UIAlertView alloc] initWithTitle:@"" message:error delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [_theAlert show];
    }
}

-(void)reconnectedToStream {
    
    // When we reconnect to the stream after a fail, we alert the user
    if (_theAlert) {
        [_theAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    self.theAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Reconnected" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [_theAlert show];
    self.theAlert = nil;
}

@end
