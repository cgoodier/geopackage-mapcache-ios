//
//  GPKGSIndexerTask.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSIndexerTask.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"
#import "GPKGFeatureIndexManager.h"

@interface GPKGSIndexerTask ()

@property (nonatomic, strong) NSNumber *maxIndex;
@property (nonatomic, strong) GPKGGeoPackage *geoPackage;
@property (nonatomic) int progress;
@property (nonatomic, strong) GPKGFeatureIndexManager *indexer;
@property (nonatomic, strong) NSObject<GPKGSIndexerProtocol> *callback;
@property (nonatomic) BOOL canceled;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) UIAlertController *alertView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation GPKGSIndexerTask

+(void) indexFeaturesWithCallback: (NSObject<GPKGSIndexerProtocol> *) callback
                                     andDatabase: (NSString *) database
                                 andTable: (NSString *) tableName
                                    andFeatureIndexType: (enum GPKGFeatureIndexType) indexLocation{
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [manager open:database];
    }
    @finally {
        [manager close];
    }
    
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
    
    GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
    [indexer setIndexLocation:indexLocation];
    
    GPKGSIndexerTask * indexTask = [[GPKGSIndexerTask alloc] initWithCallback:callback andGeoPackage:geoPackage andIndexer:indexer];
    
    int max = [featureDao count];
    [indexTask setMax:max];
    [indexer setProgress:indexTask];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@ - %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE], database, tableName]
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [indexTask setCanceled:YES];
                                                         }];
    
    UIProgressView *progressView = [GPKGSUtils buildProgressBarView];
    [alert.view addSubview:progressView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:alert.view attribute:NSLayoutAttributeTop multiplier:1 constant:78];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:alert.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:progressView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [alert.view addConstraints:@[topConstraint, leftConstraint, rightConstraint]];
    
    [alert addAction:cancelAction];
    
    indexTask.alertView = alert;
    indexTask.progressView = progressView;
    
    id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if([rootViewController isKindOfClass:[UINavigationController class]]) {
        rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
    }
    if([rootViewController isKindOfClass:[UITabBarController class]]) {
        rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
    }
    [rootViewController presentViewController:alert animated:YES completion:nil];
    
    [indexTask execute];
}

-(instancetype) initWithCallback: (NSObject<GPKGSIndexerProtocol> *) callback
                      andGeoPackage: (GPKGGeoPackage *) geoPackage
                  andIndexer: (GPKGFeatureIndexManager *) indexer{
    self = [super init];
    if(self != nil){
        self.callback = callback;
        self.geoPackage = geoPackage;
        self.indexer = indexer;
        self.progress = 0;
        self.canceled = false;
    }
    return self;
}

-(void) execute{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        
        int count = 0;
        
        @try {
            count = [self.indexer indexWithForce:true];
            if(count < [self.maxIndex intValue]){
                NSString * countError = [NSString stringWithFormat:@"Fewer features were indexed than expected. Expected: %@, Actual: %u", self.maxIndex, count];
                if(self.error != nil){
                    countError = [NSString stringWithFormat:@"%@, Error: %@", countError, self.error];
                }
                self.error = countError;
            }
        }
        @catch (NSException *e) {
            self.error = [e description];
        }
        @finally{
            [self.geoPackage close];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.alertView dismissViewControllerAnimated:YES completion:nil];

            if(self.error == nil){
                [self.callback onIndexerCompleted:count];
            }else{
                if(self.canceled){
                    [self.callback onIndexerCanceled:[self.error description]];
                }else{
                    [self.callback onIndexerFailure:[self.error description]];
                }
            }
        });
            
    });
    
}

-(void) setMax: (int) max{
    self.maxIndex = [NSNumber numberWithInt:max];
}

-(void) addProgress: (int) progress{
    self.progress += progress;
    float progressPercentage = self.progress / [self.maxIndex floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.alertView setMessage:[NSString stringWithFormat:@"( %d of %@ )", self.progress, self.maxIndex]];
        [self.progressView setProgress:progressPercentage];
    });
}

-(BOOL) isActive{
    return !self.canceled;
}

-(BOOL) cleanupOnCancel{
    return false;
}

-(void) completed{

}

-(void) failureWithError: (NSString *) error{
    self.error = error;
}

@end
