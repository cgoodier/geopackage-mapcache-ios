//
//  CreateTilesViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 1/6/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateTilesViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (strong, nonatomic) NSString *database;
@property (strong, nonatomic) NSString *featureTableName;

@end
