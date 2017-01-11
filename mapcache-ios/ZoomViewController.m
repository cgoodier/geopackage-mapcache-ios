//
//  ZoomViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 1/11/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "ZoomViewController.h"

@interface ZoomViewController ()

@property (weak, nonatomic) IBOutlet UITextField *minZoomLabel;
@property (weak, nonatomic) IBOutlet UITextField *maxZoomLabel;

@end

@implementation ZoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.minZoomLabel setText: self.data.loadTiles.generateTiles.minZoom.stringValue];
    [self.maxZoomLabel setText: self.data.loadTiles.generateTiles.maxZoom.stringValue];
}

- (IBAction)minimumZoomLabelSet:(id)sender {
    [self.data.loadTiles.generateTiles setMinZoom: [NSNumber numberWithInt:self.minZoomLabel.text.intValue]];
}

- (IBAction)maximumZoomLabelSet:(id)sender {
    [self.data.loadTiles.generateTiles setMaxZoom: [NSNumber numberWithInt:self.maxZoomLabel.text.intValue]];
}

@end
