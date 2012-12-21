//
//  WMNavigationControllerBaseViewController.m
//  Wheelmap
//
//  Created by Dorian Roy on 07.11.12.
//  Copyright (c) 2012 Sozialhelden e.V. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import "WMNavigationControllerBase.h"
#import "WMDataManager.h"
#import "WMDetailViewController.h"
#import "WMWheelchairStatusViewController.h"
#import "WMDashboardViewController.h"
#import "WMEditPOIViewController.h"
#import "WMShareSocialViewController.h"
#import "WMCategoryViewController.h"
#import "WMLoginViewController.h"
#import "Node.h"
#import "Category.h"


@implementation WMNavigationControllerBase
{
    NSArray *nodes;
    WMDataManager *dataManager;
    CLLocationManager *locationManager;
    
    WMWheelChairStatusFilterPopoverView* wheelChairFilterPopover;
    WMCategoryFilterPopoverView* categoryFilterPopover;
    
    UIView* loadingWheelContainer;  // this view will show loading whell on the center and cover child view controllers so that we avoid interactions interuptting data loading
    UIActivityIndicatorView* loadingWheel;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    dataManager = [[WMDataManager alloc] init];
    dataManager.delegate = self;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = 50.0f;
	locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    
    // configure initial vc from storyboard. this is necessary for iPad, since iPad's topVC is not the Dashboard!
    if ([self.topViewController conformsToProtocol:@protocol(WMNodeListView)]) {
        id<WMNodeListView> initialNodeListView = (id<WMNodeListView>)self.topViewController;
        initialNodeListView.dataSource = self;
        initialNodeListView.delegate = self;
    }
    
    self.wheelChairFilterStatus = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"yes",
                                   [NSNumber numberWithBool:YES], @"limited",
                                   [NSNumber numberWithBool:YES], @"no",
                                   [NSNumber numberWithBool:YES], @"unknown",nil];
    self.categoryFilterStatus = [[NSMutableDictionary alloc] init];
    for (Category* c in dataManager.categories) {
        [self.categoryFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:c.id];
    }
    
    
    loadingWheelContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    loadingWheelContainer.backgroundColor = [UIColor clearColor];
    loadingWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    loadingWheel.backgroundColor = [UIColor blackColor];
    loadingWheel.layer.cornerRadius = 5.0;
    loadingWheel.layer.masksToBounds = YES;
    loadingWheel.center = loadingWheelContainer.center;
    loadingWheelContainer.hidden = YES;
    [loadingWheelContainer addSubview:loadingWheel];
    [self.view addSubview:loadingWheelContainer];
    
    // set custom nagivation and tool bars
    self.navigationBar.frame = CGRectMake(0, self.navigationBar.frame.origin.y, self.view.frame.size.width, 50);
    self.customNavigationBar = [[WMNavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.navigationBar.frame.size.width, 50)];
    self.customNavigationBar.delegate = self;
    [self.navigationBar addSubview:self.customNavigationBar];
    self.toolbar.frame = CGRectMake(0, self.toolbar.frame.origin.y, self.view.frame.size.width, 60);
    self.toolbar.backgroundColor = [UIColor whiteColor];
    self.customToolBar = [[WMToolBar alloc] initWithFrame:CGRectMake(0, 0, self.toolbar.frame.size.width, 60)];
    self.customToolBar.delegate = self;
    [self.toolbar addSubview:self.customToolBar];
    
    // set filter popovers.
    wheelChairFilterPopover = [[WMWheelChairStatusFilterPopoverView alloc] initWithOrigin:CGPointMake(self.customToolBar.middlePointOfWheelchairFilterButton-170, self.toolbar.frame.origin.y-60)];
    wheelChairFilterPopover.hidden = YES;
    wheelChairFilterPopover.delegate = self;
    [self.view addSubview:wheelChairFilterPopover];
    
    categoryFilterPopover = [[WMCategoryFilterPopoverView alloc] initWithRefPoint:CGPointMake(self.customToolBar.middlePointOfCategoryFilterButton, self.toolbar.frame.origin.y) andCategories:dataManager.categories];
    categoryFilterPopover.delegate = self;
    categoryFilterPopover.hidden = YES;
    [self.view addSubview:categoryFilterPopover];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = UIColorFromRGB(0x304152);
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
        return YES;
    else
        return NO;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Data Manager Delegate

- (void) dataManager:(WMDataManager *)dataManager didReceiveNodes:(NSArray *)nodesParam
{
    [self hideLoadingWheel];
    nodes = nodesParam;
    
    [self refreshNodeList];
}

- (void) refreshNodeList
{
    if ([self.topViewController conformsToProtocol:@protocol(WMNodeListView)]) {
        [(id<WMNodeListView>)self.topViewController nodeListDidChange];
    }
}

-(void)dataManager:(WMDataManager *)dataManager fetchNodesFailedWithError:(NSError *)error
{
    [self hideLoadingWheel];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"FetchNodesFails", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    
    NSLog(@"error %@", error.localizedDescription);
    [self refreshNodeList];
}

- (void)dataManagerDidFinishSyncingResources:(WMDataManager *)aDataManager
{
    NSLog(@"dataManagerDidFinishSyncingResources");
    
    if ([self.topViewController isKindOfClass:[WMDashboardViewController class]]) {
        WMDashboardViewController* vc = (WMDashboardViewController*)self.topViewController;
        [vc showUIObjectsAnimated:YES];
    }
    
    [categoryFilterPopover refreshViewWithCategories:aDataManager.categories];
    [self.categoryFilterStatus removeAllObjects];
    for (Category* c in dataManager.categories) {
        [self.categoryFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:c.id];
    }
    
}

-(void)dataManager:(WMDataManager *)dataManager syncResourcesFailedWithError:(NSError *)error
{
    NSLog(@"syncResourcesFailedWithError");
    
    if ([self.topViewController isKindOfClass:[WMDashboardViewController class]]) {
        WMDashboardViewController* vc = (WMDashboardViewController*)self.topViewController;
        [vc showUIObjectsAnimated:YES];
    }
}


#pragma mark - category data source
-(NSArray*) categories
{
    return dataManager.categories;
}

#pragma mark - Node List Data Source

- (NSArray*) nodeList
{
    return nodes;
}

- (NSArray*) filteredNodeList
{
    // filter nodes here
    NSMutableArray* newNodeList = [[NSMutableArray alloc] init];
    for (Node* node in nodes) {
        NSNumber* categoryID = node.category.id;
        NSString* wheelChairStatus = node.wheelchair;
        if ([[self.wheelChairFilterStatus objectForKey:wheelChairStatus] boolValue] == YES &&
            [[self.categoryFilterStatus objectForKey:categoryID] boolValue] == YES) {
            [newNodeList addObject:node];
        }
    }
    
    return newNodeList;
}

-(void)updateNodesNear:(CLLocationCoordinate2D)coord
{
    [self showLoadingWheel];
    [dataManager fetchNodesNear:coord];
    
}

-(void)updateNodesWithRegion:(MKCoordinateRegion)region
{
    // we do not show here the loading wheel since this methods is always called by map view controller, and the vc has its own loading wheel,
    // which allows user interaction while loading nodes.
   // [self showLoadingWheel];
    CLLocationCoordinate2D southWest;
    CLLocationCoordinate2D northEast;
    southWest = CLLocationCoordinate2DMake(region.center.latitude-region.span.latitudeDelta/2.0f, region.center.longitude+region.span.longitudeDelta/2.0f);
    northEast = CLLocationCoordinate2DMake(region.center.latitude+region.span.latitudeDelta/2.0f, region.center.longitude-region.span.longitudeDelta/2.0f);
    
    [dataManager fetchNodesBetweenSouthwest:southWest northeast:northEast];
    
}

-(void)updateNodesWithQuery:(NSString*)query
{
    [self showLoadingWheel];
    [dataManager fetchNodesWithQuery:query];
    
}

-(void)updateNodesWithQuery:(NSString*) andRegion:(MKCoordinateRegion)region
{
    
}

#pragma mark - Node List Delegate

/**
 * Called only on the iPhone
 */
- (void)nodeListView:(id<WMNodeListView>)nodeListView didSelectNode:(Node *)node
{
    // we don"t want to push a detail view when selecting a node on the map view, so
    // we check if this message comes from a table view
    if (node && [nodeListView isKindOfClass:[WMNodeListViewController class]]) {
        [self pushDetailsViewControllerForNode:node];
    }
}

/**
 * Called only on the iPhone
 */
- (void) nodeListView:(id<WMNodeListView>)nodeListView didSelectDetailsForNode:(Node *)node
{
    if (node) {
        [self pushDetailsViewControllerForNode:node];
    }
}

- (void) pushDetailsViewControllerForNode:(Node*)node
{
    WMDetailViewController *detailViewController = [[UIStoryboard storyboardWithName:@"WMDetailView" bundle:nil] instantiateInitialViewController];
    detailViewController.node = node;
    [self pushViewController:detailViewController animated:YES];
}


#pragma mark - Location Manager Delegate

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Loc Error Title", @"")
                                                        message:NSLocalizedString(@"No Loc Error Message", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
	[alertView show];
}

-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"Location is updated!");
    if ([self.topViewController isKindOfClass:[WMMapViewController class]]) {
        WMMapViewController* currentVC = (WMMapViewController*)self.topViewController;
        [currentVC relocateMapTo:newLocation.coordinate];
    } else {
        [self updateNodesNear:newLocation.coordinate];
    }
}


#pragma mark - Application Notifications

- (void) applicationDidBecomeActive:(NSNotification*)notification
{
    if (locationManager) {
        [locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
	[locationManager stopUpdatingLocation];
}

#pragma mark - Push/Pop ViewControllers
- (void)pushFadeViewController:(UIViewController*)vc
{
    
    WMViewController* lastVC = [self.viewControllers lastObject];
    
    [UIView transitionFromView:lastVC.view
                        toView:vc.view
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    completion:nil];
    
    [self pushViewController:vc animated:NO];
 
    
}

-(void)popFadeViewController
{
    
  
    
    WMViewController* fromVC = [self.viewControllers lastObject];
    WMViewController* toVC = [self.viewControllers objectAtIndex:self.viewControllers.count-2];
    
    [UIView transitionFromView:fromVC.view
                        toView:toVC.view
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    completion:nil];
    
    [self popViewControllerAnimated:NO];
   

}

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
    if ([viewController conformsToProtocol:@protocol(WMNodeListView)]) {
        id<WMNodeListView> nodeListViewController = (id<WMNodeListView>)viewController;
        nodeListViewController.dataSource = self;
        nodeListViewController.delegate = self;
    }
    
    [super pushViewController:viewController animated:animated];
    [self changeScreenStatusFor:viewController];
}
-(UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    UIViewController* lastViewController = [super popViewControllerAnimated:animated];
    [self changeScreenStatusFor:[self.viewControllers lastObject]];
    
    return lastViewController;
}

-(NSArray*)popToRootViewControllerAnimated:(BOOL)animated
{
    NSArray* lastViewControllers = [super popToRootViewControllerAnimated:animated];
    
    return lastViewControllers;
}

-(NSArray*)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
    NSArray* lastViewControllers = [super popToViewController:viewController animated:animated];
    [self changeScreenStatusFor:[self.viewControllers lastObject]];
    
    return lastViewControllers;
}

-(void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    [super setViewControllers:viewControllers animated:animated];
    [self changeScreenStatusFor:[viewControllers lastObject]];
}

-(void)changeScreenStatusFor:(UIViewController*)vc
{
    // screen transition. we 
    [self hideLoadingWheel];
    
    // if the current navigation stack size is 2,then we always show DashboardButton on the left
    WMNavigationBarLeftButtonStyle leftButtonStyle;
    WMNavigationBarRightButtonStyle rightButtonStyle;
    
    if (self.viewControllers.count == 2) {
        leftButtonStyle = kWMNavigationBarLeftButtonStyleDashboardButton;
    } else {
        // otherwise, default left button is BackButton. This will be changed according to the current screen later
        leftButtonStyle = kWMNavigationBarLeftButtonStyleBackButton;
        
    }
    
    // special left buttons and right button should be set according to the current screen
    
    if ([vc isKindOfClass:[WMMapViewController class]]) {
        self.customToolBar.toggleButton.selected = YES;
        if (self.viewControllers.count == 3) {
            leftButtonStyle = kWMNavigationBarLeftButtonStyleDashboardButton;   // single exception. this is the first level!
        }
        rightButtonStyle = kWMNavigationBarRightButtonStyleContributeButton;
    } else if ([vc isKindOfClass:[WMNodeListViewController class]]) {
        WMNodeListViewController* nodeListVC = (WMNodeListViewController*)vc;
        rightButtonStyle = kWMNavigationBarRightButtonStyleContributeButton;
        self.customToolBar.toggleButton.selected = NO;
        switch (nodeListVC.useCase) {
            case kWMNodeListViewControllerUseCaseNormal:
                nodeListVC.navigationBarTitle = NSLocalizedString(@"PlacesNearby", nil);
                [self.customToolBar showAllButtons];
                break;
            case kWMNodeListViewControllerUseCaseContribute:
                nodeListVC.navigationBarTitle = NSLocalizedString(@"DashboardHelp", nil);
                [self.customToolBar hideButton:kWMToolBarButtonWheelChairFilter];
                [self.customToolBar hideButton:kWMToolBarButtonCategoryFilter];
                rightButtonStyle = kWMNavigationBarRightButtonStyleNone;
                break;
            case kWMNodeListViewControllerUseCaseCategory:
                [self.customToolBar showButton:kWMToolBarButtonWheelChairFilter];
                [self.customToolBar hideButton:kWMToolBarButtonCategoryFilter];
                break;
            case kWMNodeListViewControllerUseCaseSearch:
                nodeListVC.navigationBarTitle = NSLocalizedString(@"SearchResult", nil);
                rightButtonStyle = kWMNavigationBarRightButtonStyleNone;
            default:
                break;
        }
        
    } else if ([vc isKindOfClass:[WMDetailViewController class]]) {
        rightButtonStyle = kWMNavigationBarRightButtonStyleEditButton;
        [self hidePopover:wheelChairFilterPopover];
        [self hidePopover:categoryFilterPopover];
    } else if ([vc isKindOfClass:[WMWheelchairStatusViewController class]]) {
        rightButtonStyle = kWMNavigationBarRightButtonStyleSaveButton;
        leftButtonStyle = kWMNavigationBarLeftButtonStyleCancelButton;
        [self hidePopover:wheelChairFilterPopover];
        [self hidePopover:categoryFilterPopover];
    } else if ([vc isKindOfClass:[WMEditPOIViewController class]]) {
        rightButtonStyle = kWMNavigationBarRightButtonStyleSaveButton;
        leftButtonStyle = kWMNavigationBarLeftButtonStyleCancelButton;
        [self hidePopover:wheelChairFilterPopover];
        [self hidePopover:categoryFilterPopover];
        
    }  else if ([vc isKindOfClass:[WMShareSocialViewController class]]) {
        rightButtonStyle = kWMNavigationBarRightButtonStyleNone;
        leftButtonStyle = kWMNavigationBarLeftButtonStyleCancelButton;
        [self hidePopover:wheelChairFilterPopover];
        [self hidePopover:categoryFilterPopover];
        
    } else if ([vc isKindOfClass:[WMCategoryViewController class]]) {
        rightButtonStyle = kWMNavigationBarRightButtonStyleNone;
    }
    
    self.customNavigationBar.leftButtonStyle = leftButtonStyle;
    self.customNavigationBar.rightButtonStyle = rightButtonStyle;
    if ([vc respondsToSelector:@selector(navigationBarTitle)]) {
        self.customNavigationBar.title = [vc performSelector:@selector(navigationBarTitle)];
    }
}

#pragma mark - WMNavigationBar Delegate
-(void)pressedDashboardButton:(WMNavigationBar *)navigationBar
{
    // In the future, the dashboard would be the root VC.
    [self popToRootViewControllerAnimated:YES];
    [self hidePopover:wheelChairFilterPopover];
    [self hidePopover:categoryFilterPopover];
}

-(void)pressedBackButton:(WMNavigationBar *)navigationBar
{
    [self popViewControllerAnimated:YES];
    [self hidePopover:wheelChairFilterPopover];
    [self hidePopover:categoryFilterPopover];
    
}

-(void)pressedCancelButton:(WMNavigationBar *)navigationBar
{
    [self popViewControllerAnimated:YES];
    
}

-(void)pressedContributeButton:(WMNavigationBar *)navigationBar
{
    NSLog(@"[NavigationControllerBase] pressed contribute button!");
    WMEditPOIViewController* vc = [[UIStoryboard storyboardWithName:@"WMDetailView" bundle:nil] instantiateViewControllerWithIdentifier:@"WMEditPOIViewController"];
    vc.title = self.title = NSLocalizedString(@"EditPOIViewHeadline", @"");
    vc.node = [dataManager createNode];
    [self pushViewController:vc animated:YES];
}

-(void)pressedEditButton:(WMNavigationBar *)navigationBar
{
    WMViewController* currentViewController = [self.viewControllers lastObject];
    if ([currentViewController isKindOfClass:[WMDetailViewController class]]) {
        [(WMDetailViewController*)currentViewController pushEditViewController];
    }
}

-(void)pressedSaveButton:(WMNavigationBar *)navigationBar
{
    WMViewController* currentViewController = [self.viewControllers lastObject];
    if ([currentViewController isKindOfClass:[WMWheelchairStatusViewController class]]) {
        [(WMWheelchairStatusViewController*)currentViewController saveAccessStatus];
    }
    if ([currentViewController isKindOfClass:[WMEditPOIViewController class]]) {
        [(WMEditPOIViewController*)currentViewController saveEditedData];
    }
}

-(void)pressedSearchCancelButton:(WMNavigationBar *)navigationBar
{
    [self.customToolBar deselectSearchButton];
    
}

-(void)searchStringIsGiven:(NSString *)query
{
    [self showLoadingWheel];
    [dataManager fetchNodesWithQuery:query];
    if ([self.topViewController isKindOfClass:[WMNodeListViewController class]]) {
        WMNodeListViewController* vc = (WMNodeListViewController*)self.topViewController;
        vc.useCase = kWMNodeListViewControllerUseCaseSearch;
        vc.navigationBarTitle = NSLocalizedString(@"SearchResult", nil);
        self.customNavigationBar.title = vc.navigationBarTitle;
      
    } else if ([self.topViewController isKindOfClass:[WMMapViewController class]]) {
        WMMapViewController* vc = (WMMapViewController*)self.topViewController;
        vc.useCase = kWMNodeListViewControllerUseCaseSearch;
        vc.navigationBarTitle = NSLocalizedString(@"SearchResult", nil);;
        self.customNavigationBar.title = vc.navigationBarTitle;
        
        WMNodeListViewController* nodeListVC = (WMNodeListViewController*)[self.viewControllers objectAtIndex:self.viewControllers.count-2];
        nodeListVC.useCase = kWMNodeListViewControllerUseCaseSearch;
        nodeListVC.navigationBarTitle = NSLocalizedString(@"SearchResult", nil);;
        self.customNavigationBar.title = nodeListVC.navigationBarTitle;
       
    }
    
    
}

#pragma mark - WMToolBar Delegate
-(void)pressedToggleButton:(WMButton *)sender
{
    if ([self.topViewController isKindOfClass:[WMNodeListViewController class]]) {
        //  the node list view is on the screen. push the map view controller
        WMMapViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"WMMapViewController"];
        WMViewController* currentVC = (WMViewController*)self.topViewController;
        vc.navigationBarTitle = currentVC.navigationBarTitle;
        if ([currentVC respondsToSelector:@selector(useCase)])
            vc.useCase = (WMNodeListViewControllerUseCase)[currentVC performSelector:@selector(useCase)];
        [self pushFadeViewController:vc];
        
    } else if ([self.topViewController isKindOfClass:[WMMapViewController class]]) {
        //  the map view is on the screen. pop the map view controller
        [self popFadeViewController];
    }
    
}

-(void)pressedCurrentLocationButton:(WMToolBar *)toolBar
{
    NSLog(@"[ToolBar] update current location button is pressed!");
    [locationManager startUpdatingLocation];
    
}
-(void)pressedSearchButton:(BOOL)selected
{
    NSLog(@"[ToolBar] global search button is pressed!");
    if (selected) {
        [self.customNavigationBar showSearchBar];
    } else {
        [dataManager fetchNodesNear:locationManager.location.coordinate];
    }
}

-(void)pressedWheelChairStatusFilterButton:(WMToolBar *)toolBar
{
    NSLog(@"[ToolBar] wheelchair status filter buttton is pressed!");
    if (!categoryFilterPopover.hidden) {
        [self hidePopover:categoryFilterPopover];
    }
    
    if (wheelChairFilterPopover.hidden) {
        [self showPopover:wheelChairFilterPopover];
    } else {
        [self hidePopover:wheelChairFilterPopover];
    }
}

-(void)pressedCategoryFilterButton:(WMToolBar *)toolBar
{
    NSLog(@"[ToolBar] category filter button is pressed!");
    
    if (!wheelChairFilterPopover.hidden) {
        [self hidePopover:wheelChairFilterPopover];
    }
    
    if (categoryFilterPopover.hidden) {
        [self showPopover:categoryFilterPopover];
    } else {
        [self hidePopover:categoryFilterPopover];
    }
}

#pragma mark - Popover Management
-(void)showPopover:(UIView*)popover
{
    if (popover.hidden == NO)
        return;
    
    popover.alpha = 0.0;
    popover.transform = CGAffineTransformMakeTranslation(0, 10);
    popover.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^(void)
     {
         popover.alpha = 1.0;
         popover.transform = CGAffineTransformMakeTranslation(0, 0);
     }
                     completion:^(BOOL finished)
     {
         
     }
     ];
}

-(void)hidePopover:(UIView*)popover
{
    if (popover.hidden == YES)
        return;
    
    popover.alpha = 1.0;
    [UIView animateWithDuration:0.3 animations:^(void)
     {
         popover.alpha = 0.0;
         popover.transform = CGAffineTransformMakeTranslation(0, 10);
     }
                     completion:^(BOOL finished)
     {
         popover.hidden = YES;
         popover.transform = CGAffineTransformMakeTranslation(0, 0);
         
     }
     ];
}

#pragma mark - WMWheelchairStatusFilter Delegate
-(void)pressedButtonOfDotType:(DotType)type selected:(BOOL)selected
{
    NSString* wheelchairStatusString = @"unknown";
    switch (type) {
        case kDotTypeGreen:
            self.customToolBar.wheelChairStatusFilterButton.selectedGreenDot = selected;
            wheelchairStatusString = @"yes";
            break;
            
        case kDotTypeYellow:
            self.customToolBar.wheelChairStatusFilterButton.selectedYellowDot = selected;
            wheelchairStatusString = @"limited";
            break;
            
        case kDotTypeRed:
            self.customToolBar.wheelChairStatusFilterButton.selectedRedDot = selected;
            wheelchairStatusString = @"no";
            break;
            
        case kDotTypeNone:
            self.customToolBar.wheelChairStatusFilterButton.selectedNoneDot = selected;
            wheelchairStatusString = @"unknown";
            break;
            
        default:
            break;
    }
    
    if (selected) {
        [self.wheelChairFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:wheelchairStatusString];
    } else {
        [self.wheelChairFilterStatus setObject:[NSNumber numberWithBool:NO] forKey:wheelchairStatusString];
    }
    
    [self refreshNodeList];
    
}

-(void)clearWheelChairFilterStatus
{
    for (NSNumber* key in [self.wheelChairFilterStatus allKeys]) {
        [self.wheelChairFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:key];
    }
}

#pragma mark -WMCategoryFilterPopoverView Delegate
-(void)categoryFilterStatusDidChangeForCategoryID:(NSNumber *)categoryID selected:(BOOL)selected
{
    if (selected) {
        [self.categoryFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:categoryID];
    } else {
        [self.categoryFilterStatus setObject:[NSNumber numberWithBool:NO] forKey:categoryID];
    }
    
    [self refreshNodeList];
}

-(void)clearCategoryFilterStatus
{
    for (NSNumber* key in [self.categoryFilterStatus allKeys]) {
        [self.categoryFilterStatus setObject:[NSNumber numberWithBool:YES] forKey:key];
    }
}

#pragma mark - Loading Wheel Management
- (void) showLoadingWheel
{
    loadingWheelContainer.hidden = NO;
    [loadingWheel startAnimating];
}

- (void) hideLoadingWheel
{
    loadingWheelContainer.hidden = YES;
    [loadingWheel stopAnimating];
}

#pragma mark - UINavigationController delegate
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[WMNodeListViewController class]] || [viewController isKindOfClass:[WMMapViewController class]]) {
        if (navigationController.toolbarHidden == YES) 
            [navigationController setToolbarHidden:NO animated:YES];
    } else {
        if (navigationController.toolbarHidden == NO)
            [navigationController setToolbarHidden:YES animated:YES];
    }
    
    
    if ([viewController isKindOfClass:[WMDashboardViewController class]]) {
        if (navigationController.navigationBarHidden == NO) {
            [navigationController setNavigationBarHidden:YES animated:YES];
        }
    } else {
        if (navigationController.navigationBarHidden == YES) {
            [navigationController setNavigationBarHidden:NO animated:YES];
        }
    }
     
     
}

#pragma mark - Show Login screen
-(void)presentLoginScreen
{
    WMLoginViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"WMLoginViewController"];
    [self presentModalViewController:vc animated:YES];
}
@end




