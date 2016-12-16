//
//  FeatureHeaderTableViewCell.h
//  mapcache-ios
//
//  Created by Dan Barela on 12/16/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGFeatureDao.h"
#import "GPKGSFeatureTable.h"

@interface FeatureHeaderTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *featureTableNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *geoPackageNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfFeaturesLabel;
@property (weak, nonatomic) IBOutlet UILabel *geometryTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *xBoundsLabel;
@property (weak, nonatomic) IBOutlet UILabel *yBoundsLabel;

- (void) setupCellWithTable: (GPKGSFeatureTable *) table andDao: (GPKGFeatureDao *) dao;

@end
