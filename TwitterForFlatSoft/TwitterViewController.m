//
//  TwitterViewController.m
//  TwitterForFlatSoft
//
//  Created by Renat on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#define IS_IPAD (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
#import "TwitterViewController.h"
#import "RXMLElement.h"
@interface TwitterViewController ()

@end
static NSString *twitterAccountName= @"flatsoft";
static int numberOfTweetsPerPage = 10;
@implementation TwitterViewController
@synthesize managedObjectContext,parsedString;
-(void) dealloc{
    [tweetsArray release];
    _refreshHeaderView=nil;
    [managedObjectContext release];
    [loadingView removeFromSuperview];
    [detailController release];
    [self.parsedString release];
    [super dealloc];   
}
-(void) loadView{
    [super loadView];
    
}
-(Users*) getUserById:(uint64_t)givenId{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId==%llu",givenId];
    [request setPredicate:predicate];
   NSArray *ar= [managedObjectContext executeFetchRequest:request error:nil];
    if ([ar count]==0) {
        return nil;
    }
    return ([ar objectAtIndex:0]);
}
-(void) getTweetsToShow{
    [tweetsArray removeAllObjects];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Tweets" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//   [request setFetchLimit:numberOfTweetsPerPage];
    NSError *error;
    NSArray *ar= [managedObjectContext executeFetchRequest:request error:&error];
    NSLog(@"ar count=%i",[ar count]);
    if ([ar count]>0) {
        [tweetsArray addObjectsFromArray:ar];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
    }
}

-(void) loadTweetsForUserName:(NSURL*)url{
    NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
       
 
    RXMLElement *root = [[RXMLElement alloc] initFromURL:url]; 

    if (root!=nil && root.tag!=nil && [root.tag isEqualToString:@"statuses"]) {
        NSArray *statuses  = [root children:@"status"];
        
        int currentIndex = isLoadMoreButtonBusy? 0:[statuses count]-1;
        while (currentIndex>=0 && currentIndex<[statuses count]) {
        RXMLElement *status = [statuses objectAtIndex:currentIndex];
        if (isLoadMoreButtonBusy) currentIndex++; else currentIndex--;
            
        RXMLElement *retweeted_status = [status child:@"retweeted_status"];
        RXMLElement *parentElement = status;
        if (retweeted_status) parentElement = retweeted_status;
        RXMLElement *userElement = [parentElement child:@"user"];
                
        NSString *text = [parentElement child:@"text"].text;
        uint64_t tweetID = [parentElement child:@"id"].text.longLongValue;
        
        uint64_t userID = [userElement child:@"id"].text.longLongValue;
        
        Tweets *tweet = (Tweets *)[NSEntityDescription insertNewObjectForEntityForName:@"Tweets" inManagedObjectContext:managedObjectContext];
        
        
        NSString *dateCreated = [parentElement child:@"created_at"].text;
            NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
            NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
            
            NSArray *parts = [dateCreated componentsSeparatedByCharactersInSet:whitespaces];
            NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
            NSString *dateStr = [NSString stringWithFormat:@"%@ %@ %@",
                                 [filteredArray objectAtIndex:1],
                                 [filteredArray objectAtIndex:2],
                                 [filteredArray objectAtIndex:3]];

        
        [tweet setDate:dateStr];
        [tweet setText:text];
        [tweet setUserId:[NSNumber numberWithUnsignedLongLong:userID]];
        [tweet setTweetId:[NSNumber numberWithUnsignedLongLong:tweetID]];
        
        
          if ([self getUserById:userID]==nil) {
              Users *aUser = (Users *)[NSEntityDescription insertNewObjectForEntityForName:@"Users" inManagedObjectContext:managedObjectContext];
              
              NSString *imageURL = [userElement child:@"profile_image_url"].text;
              NSString *imageURL2 = [imageURL stringByReplacingOccurrencesOfString:@"_normal" withString:@"_reasonably_small"];
              NSString *userName = [userElement child:@"name"].text;
              
              UIImage *imageFile = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL2]]];              
              NSData *imageData = UIImagePNGRepresentation(imageFile);
              
              
            //  NSLog(@"imgData length=%i userid=%llu",imageData.length,userID);
              [aUser setUserId:[NSNumber numberWithUnsignedLongLong:userID]];
              [aUser setUserImage:imageData];
              [aUser setUserName:userName];
          }
//        [managedObjectContext performSelectorOnMainThread:@selector(save:) withObject:nil waitUntilDone:NO];
      //  NSError *error;
            [managedObjectContext save:nil];
            if (isLoadMoreButtonBusy) [tweetsArray addObject:tweet];
                //  if (error!=nil) NSLog(@"error=%@",[error description]);
    }
        if ([statuses count]>0 && !isLoadMoreButtonBusy)  [self getTweetsToShow];
    } 
    if (isLoadMoreButtonBusy) {
        isLoadMoreButtonBusy=NO;
        [self.tableView reloadData];
    }
    if (_reloading) {
        [self performSelector:@selector(doneLoadingTableViewData)];
    }
    if (launchLoading) {
        
    [loadingView stopAnimating];
    [loadingView removeFromSuperview];
    loadingView=nil;
    [darkView removeFromSuperview];
    darkView=nil;    
    launchLoading=NO;
    self.view.userInteractionEnabled=YES;
    self.tableView.userInteractionEnabled=YES;
    self.navigationController.view.userInteractionEnabled=YES;
    }
    [pool release];

}
-(void) reloadDataAndTableLoadingUpRows:(BOOL)toLoadUpRows{
    NSURL *url;
    if (toLoadUpRows) {
    if ( [tweetsArray count]>0) {
    Tweets *tweet = (Tweets*)[tweetsArray objectAtIndex:0];
    uint64_t lastId = [tweet.tweetId unsignedLongLongValue];
    url = [NSURL URLWithString:
           [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/user_timeline.xml?include_entities=true&include_rts=true&screen_name=%@&since_id=%llu",twitterAccountName,lastId]];
    } else {
        url = [NSURL URLWithString:
               [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/user_timeline.xml?include_entities=true&include_rts=true&screen_name=%@&count=%i",twitterAccountName ,numberOfTweetsPerPage]];
    }
    } else {
        uint64_t maxId=0;
        if ([tweetsArray count]>0) {
            Tweets *tweet2 = (Tweets*)[tweetsArray lastObject];
            maxId= [tweet2.tweetId unsignedLongLongValue]-1;
            url = [NSURL URLWithString:
                   [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/user_timeline.xml?include_entities=true&include_rts=true&screen_name=%@&count=%i&max_id=%llu",twitterAccountName,numberOfTweetsPerPage,maxId ]];
            } else {
            url = [NSURL URLWithString:
                   [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/user_timeline.xml?include_entities=true&include_rts=true&screen_name=%@&count=%i",twitterAccountName,numberOfTweetsPerPage ]];
        }
    }
// [self loadTweetsForUserName:url];
    [NSThread detachNewThreadSelector:@selector(loadTweetsForUserName:) toTarget:self withObject:url];
    
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"@%@",twitterAccountName];
    self.parsedString = [[NSMutableString alloc] init];
    
    darkView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"darkView.png"]];
    darkView.center= self.view.center;
    [darkView sizeToFit];
    [self.view addSubview:darkView];
    [darkView release];
    
    loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:loadingView];
    loadingView.center =self.view.center;
    [loadingView sizeToFit];
    [loadingView startAnimating];
    [loadingView release];
    
    
    if (_refreshHeaderView == nil) {
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.view addSubview:view];
		_refreshHeaderView = view;
		[view release];
		
	}
	detailController = [[DetailViewControllerViewController alloc] initWithNibName:@"DetailViewControllerViewController" bundle:nil];
    
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];

    
    tweetsArray = [[NSMutableArray alloc] init];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Tweets" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSError *error;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//    [request setFetchLimit:numberOfTweetsPerPage];
    
    
    NSArray *array = [moc executeFetchRequest:request error:&error];
    [tweetsArray addObjectsFromArray:array];
    launchLoading=YES;
    self.view.userInteractionEnabled=NO;
    self.tableView.userInteractionEnabled=NO;
    self.navigationController.view.userInteractionEnabled=NO;
    [self reloadDataAndTableLoadingUpRows:YES];
      // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bird.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(goToTwitterAccount)];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void) goToTwitterAccount{
    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:[NSString stringWithFormat:@"http://www.twitter.com/%@",twitterAccountName]]];

}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tweetsArray count]+1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"bookmarkCell";
    
    
    if (indexPath.row==([tweetsArray count])) {
        UITableViewCell *		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease]; 
        cell.accessoryType = UITableViewCellAccessoryNone;
          UIActivityIndicatorView*  activity = (UIActivityIndicatorView*)  [self.view viewWithTag:100500];
        [activity stopAnimating];
        cell.textLabel.text = @"Load more...";
        cell.textLabel.font  = [UIFont fontWithName:@"Helvetica" size:18.0f];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    

    UITableViewCell *		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease]; 
    Tweets *tweet = (Tweets*)[tweetsArray objectAtIndex:indexPath.row];
    uint64_t userId = [[tweet userId] unsignedLongLongValue];
    if (lastUserId!=userId) {
        lastUserId= userId;
        user=nil;
        user = [[self getUserById:userId] retain];    
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [user userName];
    cell.detailTextLabel.text = [tweet text];  
    cell.imageView.image = [UIImage imageWithData:user.userImage];
    CGRect frame = IS_IPAD? CGRectMake(cell.frame.origin.x+10, cell.frame.origin.y+10, 100, 100): CGRectMake(cell.frame.origin.x+5, cell.frame.origin.y+5, 70, 70);
    cell.imageView.frame = frame;
    return cell;

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
#pragma mark - Scroll view delegate methods
- (void)reloadTableViewDataSource{
	[self reloadDataAndTableLoadingUpRows:YES];
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	if (!isLoadMoreButtonBusy) {
	[self reloadTableViewDataSource];
    } else {
        _reloading=NO;
        [self performSelector:@selector(doneLoadingTableViewData)];
    }
//	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==[tweetsArray count]) {
        if (isLoadMoreButtonBusy==NO && _reloading==NO && launchLoading==NO) {
        isLoadMoreButtonBusy=YES;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            
            
            UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            view.center = CGPointMake(30, cell.frame.size.height/2);
            [view sizeToFit];
            [cell.contentView addSubview:view];
            view.tag=100500;
            [view startAnimating];
            [view release];
        cell.textLabel.text = @"Loading...";
        [self reloadDataAndTableLoadingUpRows:NO];
        }
        return;
    }
    
    
    
    UITableViewCell *cell= [self.tableView cellForRowAtIndexPath:indexPath];
    Tweets *tweet = (Tweets*)[tweetsArray objectAtIndex:indexPath.row];
    Users *aUser = [self getUserById:[tweet.userId longLongValue]];
    [self.navigationController pushViewController:detailController animated:YES];
    detailController.imageView.image =[UIImage imageWithData:aUser.userImage];
    detailController.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    detailController.imageView.contentMode = UIViewContentModeScaleAspectFit;
 //   [detailController.imageView sizeToFit];
    detailController.textView.text = cell.detailTextLabel.text;
    detailController.label.text = cell.textLabel.text;
    
    if (tweet.date) detailController.labelDate.text =[NSString stringWithString:tweet.date];
        
}

@end
