//
//  InfoTableViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 11/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "InfoTableViewController.h"
#import "GeneralInfoTableViewCell.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSTableCell.h"
#import "GPKGSConstants.h"
#import "GPKGSProperties.h"
#import "GPKGSDatabases.h"
#import "GPKGSTileTable.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTable.h"
#import <GPKGSpatialReferenceSystemDao.h>
#import "UITableViewHeaderFooterView+GeoPackage.h"
#import "FeatureTableTableViewController.h"
#import "TileTableTableViewController.h"
#import "SrsViewController.h"
#import "GPKGSUtils.h"

@interface InfoTableViewController ()

@property GPKGGeoPackage *geoPackage;
@property BOOL tileTablesExpanded;
@property BOOL featureTablesExpanded;
@property BOOL spatialReferenceSystemsExpanded;
@property (nonatomic, strong) GPKGSDatabases *active;
@property NSMutableArray *spatialReferenceSystems;

@end

@implementation InfoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setup {
    self.tileTablesExpanded = YES;
    self.featureTablesExpanded = YES;
    self.spatialReferenceSystemsExpanded = YES;
    self.active = [GPKGSDatabases getInstance];
    GPKGResultSet *srsResults = [[self.geoPackage getSpatialReferenceSystemDao] queryForAll];
    
    self.spatialReferenceSystems = [[NSMutableArray alloc] init];
    while([srsResults moveToNext]) {
        GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *)[[self.geoPackage getSpatialReferenceSystemDao] getObject:srsResults];
        [self.spatialReferenceSystems addObject:srs];
    }
    
    [srsResults close];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger rows = [self tablesInSection:section];
    if (section == 0) {
        return nil;
    } else if (section == 1) {
        if (rows != 0) {
            return [self.tileTablesExpanded ? @"\u25bc " : @"\u25b6 " stringByAppendingString:@"Tile Tables"];
        } else {
            return @"Tile Tables";
        }
    } else if (section == 2) {
        if (rows != 0) {
            return [self.featureTablesExpanded ? @"\u25bc " : @"\u25b6 "stringByAppendingString:@"Feature Tables"];
        } else {
            return @"Feature Tables";
        }
    } else if (section == 3) {
        if (rows != 0) {
            return [self.spatialReferenceSystemsExpanded ? @"\u25bc " : @"\u25b6 "stringByAppendingString:@"Spatial Reference Systems"];
        } else {
            return @"Spatial Reference Systems";
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return UITableViewAutomaticDimension;
}

-(NSInteger) tablesInSection: (NSInteger) section {
    if (section == 1) {
        return [self.geoPackage getTileTableCount];
    } else if (section == 2) {
        return [self.geoPackage getFeatureTableCount];
    } else if (section == 3) {
        return [[self.geoPackage getSpatialReferenceSystemDao] count];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return self.tileTablesExpanded ? [self tablesInSection:section] : 0;
    } else if (section == 2) {
        return self.featureTablesExpanded ? [self tablesInSection:section] : 0;
    } else if (section == 3) {
        return self.spatialReferenceSystemsExpanded ? [self tablesInSection:section] : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        GeneralInfoTableViewCell *cell = (GeneralInfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"general" forIndexPath:indexPath];
        [cell setupCellWithGeoPackage:self.geoPackage];
    
        return cell;
    } else if (indexPath.section == 1) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_TILE_TABLE forIndexPath:indexPath];
        
        NSString *tileTableName = [[self.geoPackage getTileTables] objectAtIndex:indexPath.row];
        cell.tableName.text = tileTableName;
        
        GPKGTileDao * tileDao = [self.geoPackage getTileDaoWithTableName: tileTableName];
        int count = [tileDao count];
        
        GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:self.geoPackage.name andName:tileTableName andCount:count];
        [table setActive:[self.active exists:table]];
        table.geoPackage = self.geoPackage;
        cell.table = table;
        cell.dao = tileDao;
        cell.active.table = table;
        cell.active.on = table.active;
        [cell.count setText:[NSString stringWithFormat:@"(%d)", table.count]];
        
        return cell;
    } else if (indexPath.section == 2) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_FEATURE_TABLE forIndexPath:indexPath];

        NSString *featureTableName = [[self.geoPackage getFeatureTables] objectAtIndex:indexPath.row];
        cell.tableName.text = featureTableName;
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName: featureTableName];
        int count = [featureDao count];
        
        GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] initWithDatabase:self.geoPackage.name andName:featureTableName andCount:count];
        [table setActive:[self.active exists:table]];
        table.geoPackage = self.geoPackage;
        cell.table = table;
        cell.dao = featureDao;
        cell.active.table = table;
        cell.active.on = table.active;
        [cell.count setText:[NSString stringWithFormat:@"(%d)", table.count]];
    
        return cell;
    } else if (indexPath.section == 3) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_SRS forIndexPath:indexPath];
        GPKGSpatialReferenceSystem *srs = [self.spatialReferenceSystems objectAtIndex:indexPath.row];
        cell.srs = srs;
        cell.tableName.text = [NSString stringWithFormat:@"%@ %@", srs.srsName, srs.srsId];
        
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 120.0f;
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    //GPKGSDatabase * database = (GPKGSDatabase *) [self.databases valueForKey:[self.databaseNames objectAtIndex:section]];
    
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *) view;
        [hfv.textLabel setTextColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
        hfv.data = [NSNumber numberWithInteger:section];
        NSInteger rows = [self tablesInSection:section];
        if (rows == 0) {
            /*
            hfv.detailTextLabel.text = @"No tables of this type exist in this GeoPackage";
            [hfv.detailTextLabel setTextColor: [UIColor colorWithRed:255.0f/256.0f green:221.0f/256.0f blue:160.0f/256.0f alpha:1.0f]];
             */
        } else {
            //hfv.detailTextLabel.text = nil;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
            [hfv addGestureRecognizer:tap];
        }
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
    if ([section isEqualToNumber:[NSNumber numberWithInt:1]]) {
        self.tileTablesExpanded = !self.tileTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([section isEqualToNumber:[NSNumber numberWithInt:2]]) {
        self.featureTablesExpanded = !self.featureTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([section isEqualToNumber:[NSNumber numberWithInt:3]]) {
        self.spatialReferenceSystemsExpanded = !self.spatialReferenceSystemsExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) headerButtonClick: (UIButton *) button {
    
    //[self performSegueWithIdentifier:@"showGeoPackageInfo" sender:button.geoPackage];
}

- (IBAction)tableActiveChanged:(GPKGSActiveTableSwitch *)sender {
    GPKGSTable * table = sender.table;
    table.active = sender.on;
    
    if([table getType] == GPKGS_TT_FEATURE_OVERLAY){
        [self.active removeTable:table];
        [self.active addTable:table];
    }else{
        if(table.active){
            [self.active addTable:table];
        }else{
            [self.active removeTable:table andPreserveOverlays:true];
        }
    }
    //[self updateClearActiveButton];
}

- (void) setDatabase:(GPKGSDatabase *)database {
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    self.geoPackage = [manager open:database.name];
}

- (IBAction)shareButtonPress:(id)sender {
    NSString *path = [[GPKGGeoPackageFactory getManager] documentsPathForDatabase:self.geoPackage.name];
    
    if(path != nil){
        NSURL * databaseUrl = [NSURL fileURLWithPath:path];
        
        UIDocumentInteractionController *shareDocumentController = [UIDocumentInteractionController interactionControllerWithURL:databaseUrl];
        [shareDocumentController setUTI:@"public.database"];
        [shareDocumentController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    }
    /*else{
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"Share Database %@", database]
                                 andMessage:[NSString stringWithFormat:@"No path was found for database %@", database]];
    }*/
}

- (IBAction)deleteButtonPress:(id)sender {
    NSString * label = [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_DELETE_LABEL];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:label message:[NSString stringWithFormat:@"%@ %@?", label, self.geoPackage.name] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:label
                                                           style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [self handleDeleteDatabase:action];
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {}];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];

}

- (IBAction)editButtonPress:(id)sender {
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ '%@'", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL], self.geoPackage.name] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"New GeoPackage Name";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *field = (UITextField *)[alert.textFields objectAtIndex:0];
        
        NSString * newName = field.text;
        if (newName != nil && [newName length] > 0 && ![newName isEqualToString:self.geoPackage.name]) {
            @try {
                if ([[GPKGGeoPackageFactory getManager] rename:self.geoPackage.name to:newName]){
                    [self.active renameDatabase:self.geoPackage.name asNewDatabase:newName];
                    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
                    self.geoPackage = [manager open:newName];
                    [self setup];
                    [self.tableView reloadData];
                } else {
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", self.geoPackage.name, newName]];
                     
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Rename %@ to %@", self.geoPackage.name, newName]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }

    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)copyButtonPress:(id)sender {
    
}


-(void) deleteDatabaseOption: (NSString *) database{
    NSString * label = [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_DELETE_LABEL];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:label
                                                                   message:[NSString stringWithFormat:@"%@ %@?", label, database]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:label
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                             [self handleDeleteDatabase:action];
                                                         }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {}];
    
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) handleDeleteDatabase: (UIAlertAction *)action {
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    [manager delete:self.geoPackage.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:GPKGS_DELETE_GEOPACKAGE_NOTIFICATION object:self.geoPackage.name];
    [self performSegueWithIdentifier:@"unwindToManager" sender:self];
    //[self.active removeDatabase:database andPreserveOverlays:false];
    //[self updateAndReloadData];
}

/*
- (void) handleDeleteDatabaseWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString *database = objc_getAssociatedObject(alertView, &ConstantKey);
        [self.manager delete:database];
        [self.active removeDatabase:database andPreserveOverlays:false];
        [self updateAndReloadData];
    }
}
 */



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        return NO;
    }
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *tableName;
    if (indexPath.section == 1) {
        tableName = [[self.geoPackage getTileTables] objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        tableName = [[self.geoPackage getFeatureTables] objectAtIndex:indexPath.row];
    }
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.geoPackage deleteUserTable:tableName];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"featureTableSegue"]) {
        FeatureTableTableViewController *vc = (FeatureTableTableViewController *)[segue destinationViewController];
        GPKGSTableCell *cell = (GPKGSTableCell *)sender;
        [vc setTable:(GPKGSFeatureTable *)cell.table];
        [vc setGeoPackage:self.geoPackage];
        [vc setDao:(GPKGFeatureDao *)cell.dao];
    } else if ([segue.identifier isEqualToString:@"tileTableSegue"]) {
        TileTableTableViewController *vc = (TileTableTableViewController *)[segue destinationViewController];
        GPKGSTableCell *cell = (GPKGSTableCell *)sender;
        [vc setTable:(GPKGSTileTable *)cell.table];
        [vc setGeoPackage:self.geoPackage];
        [vc setDao:(GPKGTileDao *)cell.dao];
    } else if ([segue.identifier isEqualToString:@"srsTableSegue"]) {
        SrsViewController *vc = (SrsViewController *)[segue destinationViewController];
        GPKGSTableCell *cell = (GPKGSTableCell *)sender;
        [vc setSrs:cell.srs];
    }
}


@end
