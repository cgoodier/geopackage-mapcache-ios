//
//  CreateFeatureIndexViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 1/4/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "CreateFeatureIndexViewController.h"
#import <GPKGFeatureIndexManager.h>

@interface CreateFeatureIndexViewController ()

@property (weak, nonatomic) IBOutlet UILabel *createLabel;
@property (weak, nonatomic) IBOutlet UIButton *createGeoPackageIndexButton;
@property (weak, nonatomic) IBOutlet UILabel *geoPackageIndexCreatedLabel;
@property (weak, nonatomic) IBOutlet UIButton *createMetadataIndexButton;
@property (weak, nonatomic) IBOutlet UILabel *metadataIndexCreatedLabel;

@end

@implementation CreateFeatureIndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL geoPackageIndexed = false;
    BOOL metadataIndexed = false;
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.table.name];
        
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        geoPackageIndexed = [indexer isIndexedWithFeatureIndexType:GPKG_FIT_GEOPACKAGE];
        metadataIndexed = [indexer isIndexedWithFeatureIndexType:GPKG_FIT_METADATA];
        if (!geoPackageIndexed) {
            [self.geoPackageIndexCreatedLabel setHidden:YES];
            [self.createGeoPackageIndexButton setHidden:NO];
        } else {
            [self.geoPackageIndexCreatedLabel setHidden:NO];
            [self.createGeoPackageIndexButton setHidden:YES];
        }
        
        if (!metadataIndexed) {
            [self.metadataIndexCreatedLabel setHidden:YES];
            [self.createMetadataIndexButton setHidden:NO];
        } else {
            [self.metadataIndexCreatedLabel setHidden:NO];
            [self.createMetadataIndexButton setHidden:YES];
        }
    }
    @finally {
        [geoPackage close];
    }
    
    
    self.createLabel.text = [NSString stringWithFormat:@"Create Feature Index for Table '%@'", self.table.name];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
