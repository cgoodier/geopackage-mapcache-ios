//
//  FeatureTableTableViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 12/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "FeatureTableTableViewController.h"
#import "GPKGFeatureDao.h"
#import "GPKGSTableCell.h"
#import "GPKGSConstants.h"
#import <GPKGFeatureTable.h>
#import <GPKGFeatureColumn.h>
#import <GPKGDataColumnsDao.h>
#import "UITableViewHeaderFooterView+GeoPackage.h"
#import "SrsViewController.h"
#import "GPKGSEditFeaturesViewController.h"
#import <GPKGProjectionTransform.h>
#import <GPKGProjectionConstants.h>
#import "FeatureHeaderTableViewCell.h"
#import "GPKGSProperties.h"
#import "GPKGSUtils.h"
#import <GPKGGeoPackageFactory.h>
#import "GPKGSDatabases.h"
#import "CreateFeatureIndexViewController.h"

@interface FeatureTableTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *featureTableNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfFeaturesLabel;
@property (weak, nonatomic) IBOutlet UILabel *geopackageNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *geomTypeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *xBoundsLabel;
@property (weak, nonatomic) IBOutlet UILabel *yBoundsLabel;
@property (weak, nonatomic) GPKGFeatureDao *featureDao;
@property (weak, nonatomic) GPKGFeatureTable *featureTable;
@property (strong, nonatomic) NSMutableDictionary *collapsedSections;
@property (strong, nonatomic) GPKGDataColumnsDao *dcDao;
@property (strong, nonatomic) NSString *tableIdentifier;

@end

@implementation FeatureTableTableViewController

static NSInteger const HEADER_SECTION = 0;
static NSInteger const LINKED_TILE_LAYER_SECTION = 1;
static NSInteger const SRS_SECTION = 2;
static NSInteger const GEOMETRY_COLUMN_SECTION = 3;
static NSInteger const COLUMNS_SECTION = 4;
static NSInteger const NUMBER_OF_SECTIONS = 5;

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"Feature Table";
    self.featureTable = [self.dao getFeatureTable];
    
    self.collapsedSections = [[NSMutableDictionary alloc] init];
    
    self.dcDao = [self.geoPackage getDataColumnsDao];
    GPKGGeometryColumnsDao * geometryColumnsDao = [self.table.geoPackage getGeometryColumnsDao];
    GPKGContents *contents = [geometryColumnsDao getContents:self.dao.geometryColumns];
    if (contents.identifier != nil) {
        self.tableIdentifier = [NSString stringWithFormat:@"%@", contents.identifier];
    } else {
        self.tableIdentifier = [NSString stringWithFormat:@"%@", self.table.name];
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL collpased = [(NSNumber *)[self.collapsedSections objectForKey:[NSNumber numberWithInteger:section]] boolValue];
    if (collpased) return 0;
    if (section == HEADER_SECTION || section == SRS_SECTION || section == GEOMETRY_COLUMN_SECTION) {
        return 1;
    } else if (section == COLUMNS_SECTION) {
        return [self.featureTable columns].count;
    }
    return 0;
}
//return [self.tileTablesExpanded ? @"\u25bc " : @"\u25b6 " stringByAppendingString:@"Tile Tables"];
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *arrow = [(NSNumber *)[self.collapsedSections objectForKey:[NSNumber numberWithInteger:section]] boolValue] ? @"\u25b6 " : @"\u25bc ";
    if (section == LINKED_TILE_LAYER_SECTION) {
        return [arrow stringByAppendingString:@"Linked Tile Layers"];
    } else if (section == SRS_SECTION) {
        return [arrow stringByAppendingString:@"Spatial Reference System"];
    } else if (section == GEOMETRY_COLUMN_SECTION) {
        return [arrow stringByAppendingString:@"Geometry Column"];
    } else if (section == COLUMNS_SECTION) {
        return [arrow stringByAppendingString:@"Columns"];
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == HEADER_SECTION) {
        return CGFLOAT_MIN;
    }
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *) view;
        [hfv.textLabel setTextColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
        hfv.data = [NSNumber numberWithInteger:section];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
        [hfv addGestureRecognizer:tap];
    }
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    //addButton.geoPackage = self.geoPackage;
    [addButton setTintColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
    [addButton addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:addButton];
    
    
    // Place button on far right margin of header
    addButton.translatesAutoresizingMaskIntoConstraints = NO; // use autolayout constraints instead
    [addButton.trailingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.trailingAnchor].active = YES;
    [addButton.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
}

- (void) headerClicked: (UIGestureRecognizer *) sender {
    UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *)sender.view;
    NSNumber *section = (NSNumber *)hfv.data;
    BOOL collapsed = ![(NSNumber *)[self.collapsedSections objectForKey:section] boolValue];
    
    [self.collapsedSections setObject:[NSNumber numberWithBool:collapsed] forKey:section];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:[section longValue]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) headerButtonClick: (UIButton *) button {
    
    //[self performSegueWithIdentifier:@"showGeoPackageInfo" sender:button.geoPackage];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == HEADER_SECTION) {
        FeatureHeaderTableViewCell *cell = (FeatureHeaderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"HeaderCell" forIndexPath:indexPath];
        [cell setupCellWithTable:self.table andDao:self.dao];
        return cell;
    } else if (indexPath.section == SRS_SECTION) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_SRS forIndexPath:indexPath];
        
        NSNumber *srsId = self.dao.geometryColumns.srsId;
        GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *)[[self.geoPackage getSpatialReferenceSystemDao] queryForIdObject:srsId];
        cell.srs = srs;
        cell.tableName.text = [NSString stringWithFormat:@"%@ %@", srs.srsName, srs.srsId];
        return cell;
    } else if (indexPath.section == GEOMETRY_COLUMN_SECTION) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ColumnCell" forIndexPath:indexPath];
        GPKGFeatureColumn *gc = [self.featureTable getGeometryColumn];
        cell.textLabel.text = gc.name;
        cell.detailTextLabel.text = [GPKGDataTypes name:gc.dataType];
        return cell;
    } else if (indexPath.section == COLUMNS_SECTION) {
        GPKGUserColumn *row = (GPKGUserColumn *)[[self.featureTable columns] objectAtIndex:indexPath.row];
        GPKGDataColumns *dc = [self.dcDao getDataColumnByTableName:self.table.name andColumnName:row.name];
        
        if (dc == nil) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ColumnCell" forIndexPath:indexPath];
            cell.textLabel.text = row.name;
            cell.detailTextLabel.text = [GPKGDataTypes name:[row dataType]];
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DataColumnCell" forIndexPath:indexPath];
            
            ((UILabel *)[cell viewWithTag:4]).text = row.name;
            ((UILabel *)[cell viewWithTag:1]).text = [GPKGDataTypes name:[row dataType]];
            ((UILabel *)[cell viewWithTag:2]).text = dc.name;
            ((UILabel *)[cell viewWithTag:3]).text = dc.theDescription;
            return cell;
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == HEADER_SECTION) return 144.0f;
    if (indexPath.section != COLUMNS_SECTION) return UITableViewAutomaticDimension;
    
    GPKGUserColumn *row = (GPKGUserColumn *)[[self.featureTable columns] objectAtIndex:indexPath.row];
    GPKGDataColumns *dc = [self.dcDao getDataColumnByTableName:self.table.name andColumnName:row.name];
    
    if (dc != nil) {
        return 118.0f;
    }
    return UITableViewAutomaticDimension;
}

- (IBAction)deleteButtonPressed:(id)sender {
    NSString * label = [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:label
                                                                   message:[NSString stringWithFormat:@"%@ %@ - %@?", label, self.geoPackage.name, self.table.name]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:label
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                             [self handleDelete:action];
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {}];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) handleDelete: (UIAlertAction *) action {
    GPKGGeoPackage * geoPackage = [[GPKGGeoPackageFactory getManager] open:self.table.database];
    @try {
        [geoPackage deleteUserTable:self.table.name];
        [[GPKGSDatabases getInstance] removeTable:self.table];
        [self.navigationController popViewControllerAnimated:YES];
    }
    @catch (NSException *exception) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"%@ %@ - %@ Table", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL], self.table.database, self.table.name]
                                 andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
    }
    @finally {
        [geoPackage close];
    }

}
- (IBAction)actionButtonPressed:(id)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Actions for table %@", self.tableIdentifier] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {}];
    
    UIAlertAction* indexFeaturesAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_LABEL] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"featureIndexSegue" sender:self];
    }];
    
    UIAlertAction* createFeatureTilesAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction* featureOverlayAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_ADD_FEATURE_OVERLAY_LABEL] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction* linkedTablesAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_LINKED_TABLES_LABEL] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    
    [actionSheet addAction:indexFeaturesAction];
    [actionSheet addAction:createFeatureTilesAction];
    [actionSheet addAction:featureOverlayAction];
    [actionSheet addAction:linkedTablesAction];
    [actionSheet addAction:cancelAction];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"srsTableSegue"]) {
        SrsViewController *vc = (SrsViewController *)[segue destinationViewController];
        GPKGSTableCell *cell = (GPKGSTableCell *)sender;
        [vc setSrs:cell.srs];
    } else if ([segue.identifier isEqualToString:@"featureTableEditSegue"]) {
        GPKGSEditFeaturesViewController *vc = (GPKGSEditFeaturesViewController *)[segue destinationViewController];
        [vc setManager:[GPKGGeoPackageFactory getManager]];
        [vc setDao:self.dao];
        [vc setTable:self.table];
    } else if ([segue.identifier isEqualToString:@"featureIndexSegue"]) {
        CreateFeatureIndexViewController *vc = (CreateFeatureIndexViewController *)[segue destinationViewController];
        [vc setTable:self.table];
        [vc setManager:[GPKGGeoPackageFactory getManager]];
        [vc setDao:self.dao];
    }
}

-(IBAction)unwindToFeatureTable:(UIStoryboardSegue *)segue {
}


@end
