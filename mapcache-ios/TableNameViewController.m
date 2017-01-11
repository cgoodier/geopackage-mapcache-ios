//
//  TableNameViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 1/11/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "TableNameViewController.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"

@interface TableNameViewController ()

@property (weak, nonatomic) IBOutlet UITextField *tableNameLabel;

@end

@implementation TableNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.tableName) {
        [self.tableNameLabel setText: self.tableName];
    } else if (self.featureTableName) {
        [self.tableNameLabel setText:[NSString stringWithFormat:@"%@%@", self.featureTableName, [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_NAME_SUFFIX]]];
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.tableNameLabel.inputAccessoryView = keyboardToolbar;
    
}

- (void) doneButtonPressed {
    [self.view endEditing:YES];
}

- (IBAction)tableNameChanged:(id)sender {
    self.tableName = self.tableNameLabel.text;
}

@end
