/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

#import "SearchViewController.h"
#import "NavDataStore.h"
#import "NavUtil.h"
#import "LocationEvent.h"

@interface SearchViewController () {
    BOOL updated;
}

@end

@implementation SearchViewController {
    NavSearchHistoryDataSource *historySource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.routeOptionsButton.enabled = NO;
    self.routeOptionsButton.hidden = YES;
    
    self.fromButton.titleLabel.numberOfLines = 1;
    self.fromButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.fromButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    self.toButton.titleLabel.numberOfLines = 1;
    self.toButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.toButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    NavDataStore *nds = [NavDataStore sharedDataStore];
    
    if (nds.from == nil && nds.to == nil) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hide_current_location_from_start"]) {
            nds.from = [NavDestination selectStart];
        } else {
            nds.from = [NavDataStore destinationForCurrentLocation];
        }
        nds.to = [NavDestination selectDestination];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(destinationsChanged:) name:DESTINATIONS_CHANGED_NOTIFICATION object:nil];

    historySource = [[NavSearchHistoryDataSource alloc] init];
    _historyView.dataSource = historySource;
    _historyView.delegate = self;
    [_historyView reloadData];
    
    // Do any additional setup after loading the view.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!updated) {
        [[NavDataStore sharedDataStore] reloadDestinations];
        [NavUtil showWaitingForView:self.view];
    }
    [self updateView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NavUtil hideWaitingForView:self.view];
}

- (void) destinationsChanged:(NSNotification*)notification
{
    [NavUtil hideWaitingForView:self.view];
    [self updateView];
    updated = YES;
}

- (void) updateView
{
    NavDataStore *nds = [NavDataStore sharedDataStore];
    
    self.previewButton.enabled =
    self.startButton.enabled =
    self.switchButton.enabled = (nds.to._id != nil && nds.from._id != nil);
    
    [self.fromButton setTitle:nds.from.name forState:UIControlStateNormal];
    [self.toButton setTitle:nds.to.name forState:UIControlStateNormal];
    
    self.historyClearButton.enabled = [[nds searchHistory] count] > 0;
}

- (IBAction)switchFromTo:(id)sender {
    [[NavDataStore sharedDataStore] switchFromTo];
    [self updateView];
}

- (IBAction)clearHistory:(id)sender {
    [[NavDataStore sharedDataStore] clearSearchHistory];
    [_historyView reloadData];
    [self updateView];
}

- (IBAction)previewNavigation:(id)sender {
    NavDataStore *nds = [NavDataStore sharedDataStore];
    nds.previewMode = YES;
    
    NSDictionary *prefs = @{
                            @"dist":@"500",
                            @"preset":@"9",
                            @"min_width":@"2",
                            @"slope":@"9",
                            @"road_condition":@"9",
                            @"stairs":@"9",
                            @"deff_LV":@"9",
                            @"esc":@"1",
                            @"elv":@"9"
                            };
    
    [NavUtil showWaitingForView:self.view];
    
    [[NavDataStore sharedDataStore] requestRouteFrom:nds.from._id To:nds.to._id withPreferences:prefs complete:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [NavUtil hideWaitingForView:self.view];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (IBAction)startNavigation:(id)sender {
    NavDataStore *nds = [NavDataStore sharedDataStore];
    nds.previewMode = NO;
    
    NSDictionary *prefs = @{
                            @"dist":@"500",
                            @"preset":@"9",
                            @"min_width":@"2",
                            @"slope":@"9",
                            @"road_condition":@"9",
                            @"stairs":@"9",
                            @"deff_LV":@"9",
                            @"esc":@"1",
                            @"elv":@"9"
                            };
    
    [NavUtil showWaitingForView:self.view];
    
    [[NavDataStore sharedDataStore] requestRouteFrom:nds.from._id To:nds.to._id withPreferences:prefs complete:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NavUtil hideWaitingForView:self.view];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *hist = [historySource historyAtIndexPath:indexPath];
    
    NavDataStore *nds = [NavDataStore sharedDataStore];
    nds.to = [NSKeyedUnarchiver unarchiveObjectWithData:hist[@"to"]];
    nds.from = [NSKeyedUnarchiver unarchiveObjectWithData:hist[@"from"]];
    [self updateView];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"fromSegue"]) {
        segue.destinationViewController.restorationIdentifier = @"fromDestinations";
    }
    if ([segue.identifier isEqualToString:@"toSegue"]) {
        segue.destinationViewController.restorationIdentifier = @"toDestinations";
    }
}


@end
