//
//  CreateTilesViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 1/6/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "CreateTilesViewController.h"
#import "GPKGSCreateTilesData.h"
#import <GPKGGeoPackageFactory.h>
#import <GPKGProjectionFactory.h>
#import <GPKGProjectionConstants.h>
#import <GPKGProjectionTransform.h>
#import <GPKGTileBoundingBoxUtils.h>
#import "GPKGSProperties.h"
#import <GPKGFeatureIndexManager.h>
#import "GPKGSConstants.h"

@interface CreateTilesViewController ()

@property (strong, nonatomic) NSMutableArray* pages;
@property (strong, nonatomic) GPKGSGenerateTilesData *generateTilesData;

@end

/*
Pages:
 layerName
 zoomLevels
*/

@implementation CreateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.generateTilesData = [[GPKGSGenerateTilesData alloc] init];
    
    self.view.backgroundColor = [UIColor colorWithRed:47.0/255.0f green:61.0/255.0f blue:75.0/255.0f alpha:1.0];
    if (self.featureTableName) {
        [self populateGenerateTilesData];
    }
    
    self.delegate = self;
    self.dataSource = self;
    
    self.pages = [[NSMutableArray alloc] init];
    
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"layerName"]];
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"zoomLevels"]];
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"imageStorage"]];
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"layerBounds"]];
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"maxFeatures"]];
    [self.pages addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"featureStyles"]];
    
    
    [self setViewControllers:[NSArray arrayWithObjects:[self.pages objectAtIndex:0], nil] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
        NSLog(@"Complete");
    }];
}

-(void)populateGenerateTilesData{
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    GPKGGeoPackage * geoPackage = [manager open:self.database];
    @try {
        GPKGContentsDao * contentsDao =  [geoPackage getContentsDao];
        GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:self.featureTableName];
        if(contents != nil){
            
            GPKGBoundingBox * webMercatorBoundingBox = nil;
            GPKGBoundingBox * boundingBox = nil;
            GPKGProjection * projection = nil;
            if(self.generateTilesData.boundingBox != nil){
                boundingBox = self.generateTilesData.boundingBox;
                projection = [GPKGProjectionFactory getProjectionWithInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
            }else{
                boundingBox = [contents getBoundingBox];
                projection = [contentsDao getProjection:contents];
            }
            
            GPKGProjectionTransform * webMercatorTransform = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
            if([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM){
                boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
            }
            webMercatorBoundingBox = [webMercatorTransform transformWithBoundingBox:boundingBox];
            
            // Try to find a good zoom starting point
            int zoomLevel = [GPKGTileBoundingBoxUtils getZoomLevelWithWebMercatorBoundingBox:webMercatorBoundingBox];
            int maxZoomLevel = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT] intValue];
            zoomLevel = MAX(0, MIN(zoomLevel, maxZoomLevel - 1));
            self.generateTilesData.minZoom = [NSNumber numberWithInt:zoomLevel];
            self.generateTilesData.maxZoom = [NSNumber numberWithInt:maxZoomLevel];
            
            // Check if indexed and set max features
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.featureTableName];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            BOOL indexed = [indexer isIndexed];
            self.generateTilesData.supportsMaxFeatures = true;
            if(indexed){
                NSNumber * maxFeaturesPerTile = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_FEATURE_TILES_LOAD_MAX_FEATURES_PER_TILE_DEFAULT];
                if([maxFeaturesPerTile intValue] >= 0){
                    self.generateTilesData.maxFeaturesPerTile = maxFeaturesPerTile;
                }
            }
            
            if(self.generateTilesData.boundingBox == nil){
                GPKGProjectionTransform * worldGeodeticTransform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                GPKGBoundingBox * worldGeodeticBoundingBox = [worldGeodeticTransform transformWithBoundingBox:webMercatorBoundingBox];
                self.generateTilesData.boundingBox = worldGeodeticBoundingBox;
            }
        }
    }
    @catch (NSException *exception) {
        // don't preset the bounding box
    }
    @finally {
        [geoPackage close];
    }
    
}

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger current = [self.pages indexOfObject:viewController];
    if (current+1 != [self.pages count]) {
        return [self.pages objectAtIndex:++current];
    }
    return nil;
}

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger current = [self.pages indexOfObject:viewController];
    if (current != 0) {
        return [self.pages objectAtIndex:--current];
    }
    return nil;
}

- (NSInteger) presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self.pages count];
}

- (NSInteger) presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
