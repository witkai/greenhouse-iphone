//
//  Copyright 2010-2012 the original author or authors.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  GHTweetsViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 7/26/10.
//
//
//  Based on Apple's LazyTableImages
//  http://developer.apple.com/iphone/library/samplecode/LazyTableImages/Introduction/Intro.html
//

#import "GHTweetsViewController.h"
#import "GHTweetTableViewCell.h"
#import "GHTwitterController.h"
#import "Tweet.h"
#import "GHTweetDetailsViewController.h"
#import "GHActivityIndicatorTableViewCell.h"

@interface GHTweetsViewController()

@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;

- (void)startImageDownload:(Tweet *)tweet forIndexPath:(NSIndexPath *)indexPath;
- (void)completeFetchTweets:(NSArray *)tweets;
- (BOOL)shouldShowLoadingCell:(NSUInteger)row;

@end

@implementation GHTweetsViewController

@synthesize tweets = _tweets;
@synthesize imageDownloadsInProgress;
@synthesize tweetViewController;
@synthesize tweetDetailsViewController;
@synthesize isLastPage = _isLastPage;
@synthesize isLoading = _isLoading;
@synthesize currentPage = _currentPage;

- (void)showTwitterForm
{
	[self presentModalViewController:tweetViewController animated:YES];
}

- (void)startImageDownload:(Tweet *)tweet forIndexPath:(NSIndexPath *)indexPath
{
    GHTwitterProfileImageDownloader *profileImageDownloader = [imageDownloadsInProgress objectForKey:indexPath];
	
    if (profileImageDownloader == nil) 
    {
        profileImageDownloader = [[GHTwitterProfileImageDownloader alloc] init];
        profileImageDownloader.tweet = tweet;
        profileImageDownloader.indexPathInTableView = indexPath;
        profileImageDownloader.delegate = self;
        [imageDownloadsInProgress setObject:profileImageDownloader forKey:indexPath];
        [profileImageDownloader startDownload];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their profile images yet
- (void)loadImagesForOnscreenRows
{
    if ([self.tweets count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
		
        for (NSIndexPath *indexPath in visiblePaths)
        {
			if (indexPath.row < [_tweets count])
			{
				Tweet *tweet = [self.tweets objectAtIndex:indexPath.row];
				
				if (!tweet.profileImage) // avoid the profile image download if it already has an image
				{
					[self startImageDownload:tweet forIndexPath:indexPath];
				}
			}
			else if (!_isLastPage)
			{
				// if this is the last cell in the table and we aren't on the last page, 
				// initiate the request for more tweets
				[self fetchTweetsWithPage:++_currentPage];
			}			
        }
    }
}

- (void)completeFetchTweets:(NSArray *)tweets
{
	self.isLoading = NO;
	self.tweets = tweets;
	[self.tableView reloadData];
	[self dataSourceDidFinishLoadingNewData];
}

- (void)fetchTweetsWithPage:(NSUInteger)page
{
    // in subclass
}

- (BOOL)shouldShowLoadingCell:(NSUInteger)row
{
	NSUInteger count = [_tweets count];
	return ((row == 0 && _isLoading) || (count > 0 && count == row && !_isLastPage));
}


#pragma mark -
#pragma mark TwitterControllerDelegate methods

- (void)fetchTweetsDidFinishWithResults:(NSArray *)tweets
{
//	self.isLastPage = lastPage; // value not being set by web service
    self.isLastPage = (tweets.count < TWITTER_PAGE_SIZE);
	[self completeFetchTweets:tweets];
}

- (void)fetchTweetsDidFailWithError:(NSError *)error
{
	NSArray *array = [[NSArray alloc] init];
	[self completeFetchTweets:array];
}


#pragma mark -
#pragma mark TwitterProfileImageDownloaderDelegate methods

- (void)profileImageDidLoad:(NSIndexPath *)indexPath
{
    GHTwitterProfileImageDownloader *profileImageDownloader = [imageDownloadsInProgress objectForKey:indexPath];
	
    if (profileImageDownloader != nil)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:profileImageDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        cell.imageView.image = profileImageDownloader.tweet.profileImage;
		
		[imageDownloadsInProgress removeObjectForKey:indexPath];
    }
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	// pass this delegate call on so the pull to refresh works
	[super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	
    if (!decelerate)
	{
		// Load images for all onscreen rows when scrolling is finished
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_tweets && [_tweets count] > indexPath.row)
	{
		Tweet *tweet = [_tweets objectAtIndex:indexPath.row];
        [[GHTwitterController sharedInstance] setSelectedTweet:tweet];
		[self.navigationController pushViewController:tweetDetailsViewController animated:YES];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_tweets && [_tweets count] > indexPath.row)
	{
		Tweet *tweet = [_tweets objectAtIndex:indexPath.row];
		CGSize maxSize = CGSizeMake(self.tableView.frame.size.width - 63.0f, CGFLOAT_MAX);
		CGSize textSize = [tweet.text sizeWithFont:[UIFont systemFontOfSize:13.0f] constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
		return MAX(textSize.height + 26.0f, 58.0f);
	}
	else 
	{
		return 44.0f;
	}
}


#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdent = @"tweetCell";
	static NSString *loadingCellIdent = @"loadingCell";
    
	NSUInteger tweetCount = [_tweets count];
	NSUInteger row = indexPath.row;

    // add a placeholder cell while waiting on table data
	if ([self shouldShowLoadingCell:row])
	{
        GHActivityIndicatorTableViewCell *cell = (GHActivityIndicatorTableViewCell *)[tableView dequeueReusableCellWithIdentifier:loadingCellIdent];
		
        if (cell == nil)
		{
            cell = [[GHActivityIndicatorTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:loadingCellIdent];
            cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.detailTextLabel.text = @"Loading Tweets…";
        }
		
		[cell startAnimating];
				
		return cell;
    }
	
	GHTweetTableViewCell *cell = (GHTweetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdent];
	
	if (cell == nil)
	{
		cell = [[GHTweetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdent];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
		
	// Leave cells empty if there's no data yet
    if (tweetCount > 0)
	{
        Tweet *tweet = [_tweets objectAtIndex:row];
		
        // Only load cached images; defer new downloads until scrolling ends
        if (!tweet.profileImage)
        {
            if (tableView.dragging == NO && tableView.decelerating == NO)
            {
                [self startImageDownload:tweet forIndexPath:indexPath];
            }
        }

		cell.tweet = tweet;
    }	
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (_isLoading)
	{
		return 1;
	}
	
	NSUInteger count = [_tweets count];
	
	if (count > 0 && !_isLastPage)
	{
		count++;
	}
		
	return count;
}


#pragma mark -
#pragma mark PullRefreshTableViewController methods

- (void)reloadData
{
	if (self.shouldReloadData)
	{
		[self reloadTableViewDataSource];
	}
}

- (BOOL)shouldReloadData
{
	return (_isLoading || [_tweets count] == 0 || self.lastRefreshExpired);
}

- (void)reloadTableViewDataSource
{
	self.currentPage = 1;
	self.isLastPage = NO;
	[imageDownloadsInProgress removeAllObjects];
	self.tweets = nil;
    [self fetchTweetsWithPage:_currentPage];
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.title = @"Tweets";
	self.imageDownloadsInProgress = [[NSMutableDictionary alloc] init];
	UIBarButtonItem *buttonItemCompose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
																				target:self 
																				action:@selector(showTwitterForm)];
	self.navigationItem.rightBarButtonItem = buttonItemCompose;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.isLoading = YES;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
	
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
	[imageDownloadsInProgress removeAllObjects];
	
	// delete cached profile images
	[_tweets makeObjectsPerformSelector:@selector(removeCachedProfileImage)];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
	
	self.tweets = nil;
	self.imageDownloadsInProgress = nil;
	self.tweetViewController = nil;
	self.tweetDetailsViewController = nil;
}

@end
