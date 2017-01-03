//
//  GPKGSEditFeaturesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSEditContentsData.h"
#import <LHSKeyboardAdjusting/LHSKeyboardAdjusting.h>

@class GPKGSEditFeaturesViewController;

@protocol GPKGSEditFeaturesDelegate <NSObject>
- (void)editFeaturesViewController:(GPKGSEditFeaturesViewController *)controller editedFeatures:(BOOL)edited withError: (NSString *) error;
@end

@interface GPKGSEditFeaturesViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, LHSKeyboardAdjusting>

@property (nonatomic, weak) id <GPKGSEditFeaturesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGFeatureDao *dao;
@property (nonatomic, strong) GPKGSTable *table;
@property (weak, nonatomic) IBOutlet UITextField *zTextField;
@property (weak, nonatomic) IBOutlet UITextField *mTextField;
@property (weak, nonatomic) IBOutlet UILabel *projectionLabel;

@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;

@end
