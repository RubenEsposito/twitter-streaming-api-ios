//
//  TSMapAnnotation.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

/*
 
 This class represents a Tweet annotation in the map
 
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TSMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *id_str;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign)CLLocationCoordinate2D coordinate;

@end
