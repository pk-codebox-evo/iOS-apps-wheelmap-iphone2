//
//  WMOSMLogoutViewController.m
//  Wheelmap
//
//  Created by npng on 12/12/12.
//  Copyright (c) 2012 Sozialhelden e.V. All rights reserved.
//

#import "WMOSMLogoutViewController.h"
#import "WMDataManager.h"
#import "WMNavigationControllerBase.h"

@interface WMOSMLogoutViewController ()
{
    WMDataManager* dataManager;
}
@end

@implementation WMOSMLogoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.navigationController.navigationBar setBackgroundColor:[UIColor wmNavigationBackgroundColor]];
    dataManager = [[WMDataManager alloc] init];
    
    self.titleLabel.text = NSLocalizedString(@"Sign Out", nil);
    self.topTextLabel.text = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Signed In", nil)];//, dataManager.currentUserName];
    
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.logoutButton setTitle:NSLocalizedString(@"Sign Out", nil) forState:UIControlStateNormal];

    self.logoutButton.frame = CGRectMake(320.0f - self.logoutButton.frame.size.width - 10.0f, self.logoutButton.frame.origin.y, self.logoutButton.frame.size.width, self.logoutButton.frame.size.height);
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedCancelButton:)];
    [self.view addGestureRecognizer:tapGR];
}

-(IBAction)pressedLogoutButton:(id)sender {
    [dataManager removeUserAuthentication];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [(WMToolBar_iPad *)((WMNavigationControllerBase *)self.baseController).customToolBar updateLoginButton];
    }
    
    [self dismissViewControllerAnimated:YES];
}

-(IBAction)pressedCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES];
}

@end
