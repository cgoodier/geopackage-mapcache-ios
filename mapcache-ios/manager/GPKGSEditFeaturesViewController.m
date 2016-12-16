//
//  GPKGSEditFeaturesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditFeaturesViewController.h"
#import "GPKGSEditContentsViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSDecimalValidator.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"

NSString * const GPKGS_MANAGER_EDIT_FEATURES_SEG_EDIT_CONTENTS = @"editContents";

@interface GPKGSEditFeaturesViewController ()

@property (nonatomic, strong) GPKGSEditContentsData *data;
@property (nonatomic, strong) GPKGSDecimalValidator * zAndMValidator;
@property (nonatomic, strong) NSArray * geometryTypes;
@property (nonatomic, strong) GPKGSDecimalValidator * xAndYValidator;
@property (weak, nonatomic) IBOutlet UITextField *identifierTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *minYTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxYTextField;
@property (weak, nonatomic) IBOutlet UITextField *minXTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxXTextField;

@end

@implementation GPKGSEditFeaturesViewController

#define TAG_GEOMETRY_TYPES 1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.geometryTypes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    
    self.zAndMValidator = [[GPKGSDecimalValidator alloc] initWithMinimumInt:0 andMaximumInt:2];
    [self.zTextField setDelegate:self.zAndMValidator];
    [self.mTextField setDelegate:self.zAndMValidator];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.zTextField.inputAccessoryView = keyboardToolbar;
    self.zTextField.inputAccessoryView = keyboardToolbar;
    
    [self setFields];
}

- (void) doneButtonPressed {
    [self.zTextField resignFirstResponder];
    [self.zTextField resignFirstResponder];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButton:(id)sender {
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGGeometryColumnsDao * geometryColumnsDao = [geoPackage getGeometryColumnsDao];
        GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
        GPKGGeometryColumns * geometryColumns = (GPKGGeometryColumns *)[geometryColumnsDao queryForTableName:self.table.name];
        GPKGContents * contents = [geometryColumnsDao getContents:geometryColumns];
        
        [contents setIdentifier:self.data.identifier];
        [contents setTheDescription:self.data.theDescription];
        [contents setMinY:self.data.minY];
        [contents setMaxY:self.data.maxY];
        [contents setMinX:self.data.minX];
        [contents setMaxX:self.data.maxX];
        [contents setLastChange:[NSDate date]];
        [contentsDao update:contents];
        
        enum WKBGeometryType geometryType = [WKBGeometryTypes fromName:self.geometryTypeButton.titleLabel.text];
        [geometryColumns setGeometryType:geometryType];
        
        NSNumber * zNumber = nil;
        if(self.zTextField.text.length > 0){
            int z = [self.zTextField.text intValue];
            zNumber = [[NSNumber alloc] initWithInt:z];
        }
        [geometryColumns setZ:zNumber];
        
        NSNumber * mNumber = nil;
        if(self.mTextField.text.length > 0){
            int m = [self.mTextField.text intValue];
            mNumber = [[NSNumber alloc] initWithInt:m];
        }
        [geometryColumns setM:mNumber];
        
        [geometryColumnsDao update:geometryColumns];
        
        if(self.delegate != nil){
            [self.delegate editFeaturesViewController:self editedFeatures:true withError:nil];
        }
    }
    @catch (NSException *e) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:@"Edit Features"
                                 andMessage:[NSString stringWithFormat:@"Error editing features table '%@' in database: '%@'\n\nError: %@", self.table.name, self.table.database, [e description]]];
    }
    @finally {
        [geoPackage close];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_GEOMETRY_TYPES:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.geometryTypes count]){
                    NSString * geometryType = (NSString *)[self.geometryTypes objectAtIndex:buttonIndex];
                    [self.geometryTypeButton setTitle:geometryType forState:UIControlStateNormal];
                }
            }
            
            break;
    }
    
}

- (IBAction)geometryType:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPE_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *geometryType in self.geometryTypes) {
        [alert addButtonWithTitle:geometryType];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_GEOMETRY_TYPES;
    
    [alert show];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_EDIT_FEATURES_SEG_EDIT_CONTENTS])
    {
        [self setFields];
        GPKGSEditContentsViewController *editContentsViewController = segue.destinationViewController;
        editContentsViewController.data = self.data;
    }
}

-(void) setFields{
    
    self.data = [[GPKGSEditContentsData alloc] init];
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGGeometryColumnsDao * geometryColumnsDao = [geoPackage getGeometryColumnsDao];
        GPKGGeometryColumns * geometryColumns = (GPKGGeometryColumns *)[geometryColumnsDao queryForTableName:self.table.name];
        GPKGContents * contents = [geometryColumnsDao getContents:geometryColumns];
        
        [self.data setIdentifier:contents.identifier];
        [self.data setTheDescription:contents.theDescription];
        [self.data setMinY:contents.minY];
        [self.data setMaxY:contents.maxY];
        [self.data setMinX:contents.minX];
        [self.data setMaxX:contents.maxX];
        
        enum WKBGeometryType geometryType = [geometryColumns getGeometryType];
        [self.geometryTypeButton setTitle:[WKBGeometryTypes name:geometryType] forState:UIControlStateNormal];
        [self.zTextField setText:[geometryColumns.z stringValue]];
        [self.mTextField setText:[geometryColumns.m stringValue]];
    }
    @finally {
        [geoPackage close];
    }
    
    self.xAndYValidator = [[GPKGSDecimalValidator alloc] initWithMinimum:nil andMaximum:nil];
    [self.minYTextField setDelegate:self.xAndYValidator];
    [self.maxYTextField setDelegate:self.xAndYValidator];
    [self.minXTextField setDelegate:self.xAndYValidator];
    [self.maxXTextField setDelegate:self.xAndYValidator];
    
    [self.identifierTextField setText:self.data.identifier];
    [self.descriptionTextField setText:self.data.theDescription];
    if(self.data.minY != nil){
        [self.minYTextField setText:[self.data.minY stringValue]];
    }
    if(self.data.maxY != nil){
        [self.maxYTextField setText:[self.data.maxY stringValue]];
    }
    if(self.data.minX != nil){
        [self.minXTextField setText:[self.data.minX stringValue]];
    }
    if(self.data.maxX != nil){
        [self.maxXTextField setText:[self.data.maxX stringValue]];
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.identifierTextField.inputAccessoryView = keyboardToolbar;
    self.descriptionTextField.inputAccessoryView = keyboardToolbar;
    self.minYTextField.inputAccessoryView = keyboardToolbar;
    self.maxYTextField.inputAccessoryView = keyboardToolbar;
    self.minXTextField.inputAccessoryView = keyboardToolbar;
    self.maxXTextField.inputAccessoryView = keyboardToolbar;

    
}

- (IBAction)identifierChanged:(id)sender {
    [self.data setIdentifier:self.identifierTextField.text];
}

- (IBAction)descriptionChanged:(id)sender {
    [self.data setTheDescription:self.descriptionTextField.text];
}

- (IBAction)minYChanged:(id)sender {
    NSDecimalNumber * minYNumber = nil;
    if(self.minYTextField.text.length > 0){
        double minY = [self.minYTextField.text doubleValue];
        minYNumber = [[NSDecimalNumber alloc] initWithDouble:minY];
    }
    [self.data setMinY:minYNumber];
}

- (IBAction)maxYChanged:(id)sender {
    NSDecimalNumber * maxYNumber = nil;
    if(self.maxYTextField.text.length > 0){
        double maxY = [self.maxYTextField.text doubleValue];
        maxYNumber = [[NSDecimalNumber alloc] initWithDouble:maxY];
    }
    [self.data setMaxY:maxYNumber];
}

- (IBAction)minXChanged:(id)sender {
    NSDecimalNumber * minXNumber = nil;
    if(self.minXTextField.text.length > 0){
        double minX = [self.minXTextField.text doubleValue];
        minXNumber = [[NSDecimalNumber alloc] initWithDouble:minX];
    }
    [self.data setMinX:minXNumber];
}

- (IBAction)maxXChanged:(id)sender {
    NSDecimalNumber * maxXNumber = nil;
    if(self.maxXTextField.text.length > 0){
        double maxX = [self.maxXTextField.text doubleValue];
        maxXNumber = [[NSDecimalNumber alloc] initWithDouble:maxX];
    }
    [self.data setMaxX:maxXNumber];
}


@end
