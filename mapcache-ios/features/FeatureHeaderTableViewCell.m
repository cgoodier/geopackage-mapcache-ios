//
//  FeatureHeaderTableViewCell.m
//  mapcache-ios
//
//  Created by Dan Barela on 12/16/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "FeatureHeaderTableViewCell.h"
#import <GPKGProjectionTransform.h>
#import <GPKGProjectionConstants.h>
#import <GPKGContents.h>
#import <WKBGeometryTypes.h>

@implementation FeatureHeaderTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setupCellWithTable: (GPKGSFeatureTable *) table andDao: (GPKGFeatureDao *) dao {
    GPKGProjectionTransform * projectionToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:dao.projection andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    
    GPKGGeometryColumnsDao * geometryColumnsDao = [table.geoPackage getGeometryColumnsDao];
    GPKGContents *contents = [geometryColumnsDao getContents:dao.geometryColumns];
    if (contents.identifier != nil) {
        self.featureTableNameLabel.text = [NSString stringWithFormat:@"%@", contents.identifier];
    } else {
        self.featureTableNameLabel.text = [NSString stringWithFormat:@"%@", table.name];
    }
    self.numberOfFeaturesLabel.text = [NSString stringWithFormat:@"%d Features", table.count];
    self.geoPackageNameLabel.text = [NSString stringWithFormat:@"GeoPackage: %@", table.geoPackage.name];
    
    self.geometryTypeLabel.text = [NSString stringWithFormat:@"Geometry Type: %@", [WKBGeometryTypes name:table.geometryType]];
    
    GPKGBoundingBox *box = [dao getBoundingBox];
    GPKGBoundingBox *espg4326box = [projectionToWebMercator transformWithBoundingBox:box];
    self.xBoundsLabel.text = [NSString stringWithFormat:@"Longitude: %.2f to %.2f", [espg4326box.minLongitude doubleValue], [espg4326box.maxLongitude doubleValue]];
    self.yBoundsLabel.text = [NSString stringWithFormat:@"Latitude: %.2f to %.2f", [espg4326box.minLatitude doubleValue], [espg4326box.maxLatitude doubleValue]];
}

@end
