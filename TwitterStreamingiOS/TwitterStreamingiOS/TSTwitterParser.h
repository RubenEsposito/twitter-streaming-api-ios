//
//  TSTwitterParser.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

/*
 
 This parser receives the JSON data from the Twitter Streaming API and parses it into a NSDictionary
 
 */

#import <Foundation/Foundation.h>
#import "TSTwitterParserDelegate.h"

@interface TSTwitterParser : NSObject

@property (nonatomic, weak) id<TSTwitterParserDelegate> delegate;

- (NSDictionary *)getTweetsFromData:(NSData *)data;

@end
