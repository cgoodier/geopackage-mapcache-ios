//
//  CreateFeatureIndexViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 1/4/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import <GPKGGeoPackageManager.h>

@interface CreateFeatureIndexViewController : UIViewController

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGFeatureDao *dao;
@property (nonatomic, strong) GPKGSTable *table;

@end
