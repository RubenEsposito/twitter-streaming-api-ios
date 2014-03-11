//
//  TSTwitterManager.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

/*
 
 The Manager assumes the responsibility to maintain the streaming connection, storing the data received and passing it to the delegate
 
 */

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

#import "TSTwitterManagerDelegate.h"
#import "TSTwitterParserDelegate.h"

@interface TSTwitterManager : NSObject <NSFetchedResultsControllerDelegate, TSTwitterParserDelegate>

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isTryingToConnect;
@property (nonatomic, weak) id<TSTwitterManagerDelegate> delegate;

-(void)initManager;
- (void)initStreamingConnectionForPattern:(NSString *)aKeyword;

@end
