//
//  TSTwitterManagerDelegate.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSTweet;

@protocol TSTwitterManagerDelegate <NSObject>

-(void)insertedNewTweet:(TSTweet *)tweet;
-(void)deletedTweet:(TSTweet *)tweet;
-(void)fetchingTweetsFailedWithError:(NSString *)error;
-(void)reconnectedToStream;

@end
