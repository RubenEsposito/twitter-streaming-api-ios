//
//  TSTwitterMap.h
//  TwitterStreamingiOS
//
//  Created by Rubén Expósito Marín on 11/03/14.
//  Copyright (c) 2014 Ruben Exposito Marin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TSTwitterManagerDelegate.h"

@interface TSTwitterMap : UIViewController <TSTwitterManagerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *theMap;
@property (nonatomic, strong) UIAlertView *theAlert;

@end
