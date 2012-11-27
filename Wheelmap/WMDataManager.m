//
//  WMDataManager.m
//  Wheelmap
//
//  Created by Dorian Roy on 07.11.12.
//  Copyright (c) 2012 Sozialhelden e.V. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "WMDataManager.h"
#import "WMWheelmapAPI.h"

#define WMSearchRadius 0.004

@interface WMDataManager()
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@end

@implementation WMDataManager
{
    WMWheelmapAPI *api;
    NSManagedObjectContext *_managedObjectContext;
}

- (id) init
{
    self = [super init];
    if (self) {
        api = [[WMWheelmapAPI alloc] init];
    }
    return self;
}


#pragma mark - Fetch Nodes

- (void) fetchNodesNear:(CLLocationCoordinate2D)location
{
    // get rect of area within search radius around current location
    // this rect won"t have the same proportions as the map area on screen
    CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(location.latitude - WMSearchRadius, location.longitude - WMSearchRadius);
    CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(location.latitude + WMSearchRadius, location.longitude + WMSearchRadius);
    
    [self fetchNodesBetweenSouthwest:southwest northeast:northeast];
}

- (void) fetchNodesBetweenSouthwest:(CLLocationCoordinate2D)southwest northeast:(CLLocationCoordinate2D)northeast
{
    NSString *coords = [NSString stringWithFormat:@"%f,%f,%f,%f",
                         southwest.longitude,
                         southwest.latitude,
                         northeast.longitude,
                         northeast.latitude];
    [self fetchNodesWithParameters:@{@"bbox":coords}];
}

- (void) fetchNodesWithParameters:(NSDictionary*)parameters;
{
    [api requestResource:@"nodes"
              parameters:parameters
                    data:nil
                  method:nil
                   error:^(NSError *error) {
                       [self.delegate dataManager:self fetchNodesFailedWithError:error];
                   }
                 success:^(NSDictionary *data) {
                     [self didReceiveNodes:data[@"nodes"]];
                 }
     ];
}

- (void) didReceiveNodes:(NSArray *)nodes
{
    // TODO: cache nodes
    [self.delegate dataManager:self didReceiveNodes:nodes];
}


#pragma mark - Sync Resources

- (void) syncResources
{
    // TODO: fetch data and cache it
    [self.delegate dataManagerDidFinishSyncingResources:self];
}


#pragma mark - Expose Data

- (NSArray *)categories
{
    // TODO: return data
    return nil;
}

- (NSArray *)types
{
    // TODO: return data
    return nil;
}


#pragma mark - Core Data Stack

/**
 Returns a single instance of a managed object context.
 If the context doesn't already exist, it is created with the preset
 database name and bound to a SQLite persistent store.
 */
- (NSManagedObjectContext*) managedObjectContext
{
    if (!_managedObjectContext) {
        
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
        
        // create model
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WMDataModel" withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        // create store coordinator
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        // get store URL
        NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *persistentStoreURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"WMDatabase.sqlite"];
        
        NSError *error = nil;
        // if we can't add store to coordinator...
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:persistentStoreURL
                                                            options:nil
                                                              error:NULL]) {
            
            // ... we ignore the error, and if the file already exists but is not compatible, we try to replace it with a new store file
            if ([[NSFileManager defaultManager] fileExistsAtPath:persistentStoreURL.path]) {
                
                // get metadata of existing store
                NSDictionary *metaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:persistentStoreURL error:NULL];
                
                // if meta data can't be read or model is not compatible
                if (!metaData || ![managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:metaData]) {
                    
                    // if old store file can be removed
                    if ([[NSFileManager defaultManager] removeItemAtPath:persistentStoreURL.path error:&error]) {
                        
                        // try to add new store
                        [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                 configuration:nil
                                                                           URL:persistentStoreURL
                                                                       options:nil
                                                                         error:&error];
                    }
                }
            }
        }
        
        if (error) {
            // this is an unrecoverable error, so we show an alert and crash
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fatal Error" message:@"Could not create local database" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            
        } else {
            // assign coordinator to context
            [moc setPersistentStoreCoordinator:persistentStoreCoordinator];
            
            _managedObjectContext = moc;
        }
    }
    
    return _managedObjectContext;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    abort();
}


@end




