//
//  TwitterViewController.h
//  TwitterForFlatSoft
//
//  Created by Renat on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "Users.h"
#import "Tweets.h"
#import "DetailViewControllerViewController.h"
@interface TwitterViewController : UITableViewController<EGORefreshTableHeaderDelegate,NSXMLParserDelegate>{
    UIActivityIndicatorView *loadingView ;
    NSMutableArray *tweetsArray;
    NSManagedObjectContext *managedObjectContext;
       uint64_t lastUserId;
    Users *user;
    EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL isLoadMoreButtonBusy;
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes 
	BOOL _reloading;
    BOOL launchLoading;
    UIImageView *darkView;
    DetailViewControllerViewController *detailController;
}
@property (nonatomic,retain) NSMutableString *parsedString;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;
@property (nonatomic,retain) NSManagedObjectContext *managedObjectContext;
@end
