//
//  CreateTilesWizardViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 1/11/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSGenerateTilesData.h"

@interface CreateTilesWizardViewController : UIViewController

@property (nonatomic, strong) GPKGSGenerateTilesData *data;
@property (nonatomic, strong) NSString *featureTableName;
@property (nonatomic, strong) NSString *tableName;


@end
