//
//  FeatureTableEditViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 12/16/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"

@interface FeatureTableEditViewController : UIViewController

@property (nonatomic, strong) GPKGSTable *table;
@property (weak, nonatomic) IBOutlet UITextField *zTextField;
@property (weak, nonatomic) IBOutlet UITextField *mTextField;

@end
