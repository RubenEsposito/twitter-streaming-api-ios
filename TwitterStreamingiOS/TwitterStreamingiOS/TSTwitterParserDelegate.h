//
//  TSTwitterParserDelegate.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSTwitterParserDelegate <NSObject>

// Invoked when the parser fails
- (void)parsingTweetsFailedWithError:(NSError *)error;

@end
