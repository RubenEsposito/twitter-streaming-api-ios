//
//  TSTwitterParser.m
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import "TSTwitterParser.h"

@implementation TSTwitterParser

- (NSDictionary *)getTweetsFromData:(NSData *)data {
    
    // It uses the NSJSONSerialization class introduced in iOS5
    // This simplifies tremendously the parsing task
    NSError *error = nil;
    NSDictionary *tweetsArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    // If something goes wrong, tell the delegate
    if (error) {
        [self.delegate parsingTweetsFailedWithError:error];
        return nil;
    }
    
    return tweetsArray;
}

@end
