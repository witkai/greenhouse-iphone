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
//  GHTwitterController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 8/27/10.
//

#import "GHTwitterController.h"
#import "GHURLRequestParameters.h"
#import "GHCoreDataManager.h"

@implementation GHTwitterController

@synthesize delegate;


#pragma mark -
#pragma mark Instance methods

- (void)sendRequestForTweetsWithURL:(NSURL *)url page:(NSUInteger)page delegate:(id<GHTwitterControllerDelegate>)d
//- (void)sendRequestForTweetsWithEventId:(NSNumber *)eventId page:(NSUInteger)page delegate:(id<GHTwitterControllerDelegate>)d
{
	NSString *urlString = [[NSString alloc] initWithFormat:@"%@?page=%d&pageSize=%d", [url absoluteString], page, TWITTER_PAGE_SIZE];
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             NSMutableArray *tweets = [[NSMutableArray alloc] init];
             BOOL lastPage = NO;
             
             NSError *error;
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             if (!error)
             {
                 DLog(@"%@", dictionary);
                 lastPage = [dictionary boolForKey:@"lastPage"];
                 NSArray *jsonArray = [dictionary objectForKey:@"tweets"];
                 // TODO: delete tweets?
                 [self storeTweetsWithJson:jsonArray];
                 // TODO: fetch tweets from db?
             }
             [d fetchTweetsDidFinishWithResults:tweets lastPage:lastPage];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate fetchTweetsDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the list of tweets." response:response];
         }
     }];
}

- (void)storeTweetsWithJson:(NSArray *)tweets
{
    DLog(@"");
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    [tweets enumerateObjectsUsingBlock:^(NSDictionary *tweetDict, NSUInteger idx, BOOL *stop) {
        Tweet *tweet = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Tweet"
                        inManagedObjectContext:context];
        tweet.tweetId = [tweetDict stringForKey:@"id"];
        tweet.text = [[tweetDict stringForKey:@"text"] stringByXMLDecoding];
        tweet.createdAt = [tweetDict dateWithMillisecondsSince1970ForKey:@"createdAt"];
        tweet.fromUser = [tweetDict stringByReplacingPercentEscapesForKey:@"fromUser" usingEncoding:NSUTF8StringEncoding];
        tweet.profileImageUrl = [[tweetDict stringForKey:@"profileImageUrl"] stringByURLDecoding];
        tweet.userId = [tweetDict stringForKey:@"userId"];
        tweet.languageCode = [tweetDict stringForKey:@"languageCode"];
        tweet.source = [[tweetDict stringForKey:@"source"] stringByURLDecoding];
    }];
    
    NSError *error;
    [context save:&error];
    if (error)
    {
        DLog(@"%@", [error localizedDescription]);
    }
}

- (NSArray *)fetchTweetsWithEventId:(NSNumber *)eventId
{
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tweet" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event.eventId == %@", eventId];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}

//- (void)fetchTweetsDidFinishWithData:(NSData *)data
//{
//	DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//	
//	NSMutableArray *tweets = [[NSMutableArray alloc] init];
//	BOOL lastPage = NO;
//    
//    NSError *error;
//    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//    if (!error)
//    {
//        DLog(@"%@", dictionary);
//        lastPage = [dictionary boolForKey:@"lastPage"];
//        NSArray *jsonArray = (NSArray *)[dictionary objectForKey:@"tweets"];        
//        [jsonArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            [tweets addObject:[[GHTweet alloc] initWithDictionary:obj]];
//        }];
//    }
//
//	if ([delegate respondsToSelector:@selector(fetchTweetsDidFinishWithResults:lastPage:)])
//	{
//		[delegate fetchTweetsDidFinishWithResults:tweets lastPage:lastPage];
//	}
//}

//- (void)fetchTweetsDidFailWithError:(NSError *)error
//{
//	[self requestDidFailWithError:error];
//	
//	if ([delegate respondsToSelector:@selector(fetchTweetsDidFailWithError:)])
//	{
//		[delegate fetchTweetsDidFailWithError:error];
//	}
//}

- (void)postUpdate:(NSString *)update withURL:(NSURL *)url
{
	CLLocation *location = [[CLLocation alloc] init];
	[self postUpdate:update withURL:url location:location];
}

- (void)postUpdate:(NSString *)update withURL:(NSURL *)url location:(CLLocation *)location
{
	self.activityAlertView = [[GHActivityAlertView alloc] initWithActivityMessage:@"Posting tweet..."];
	[_activityAlertView startAnimating];

    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	NSString *status = [update stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	DLog(@"tweet length: %i", status.length);

//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
//                            status, @"status",
//                            location.coordinate.latitude, @"latitude",
//                            location.coordinate.longitude, @"longitude",
//                            nil];
//    GHURLRequestParameters *postParams = [[GHURLRequestParameters alloc] initWithDictionary:params];
	
	NSString *postParams = [[NSString alloc] initWithFormat:@"status=%@&latitude=%f&longitude=%f",
                            [status stringByURLEncoding],
							location.coordinate.latitude,
                            location.coordinate.longitude];
	DLog(@"%@", postParams);
	NSData *postData = [postParams dataUsingEncoding:NSUTF8StringEncoding];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];

	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [_activityAlertView stopAnimating];
         self.activityAlertView = nil;
         
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             [self postUpdateDidFinishWithData:data];
         }
         else if (error)
         {
             [self postUpdateDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             NSString *msg = nil;
             switch (statusCode)
             {
                 case 412:
                     msg = @"Your account is not connected to Twitter. Please sign in to greenhouse.springsource.org to connect.";
                     break;
                 case 403:
                 default:
                     msg = @"A problem occurred while posting to Twitter.";
                     break;
             }
             
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:msg
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
             [alertView show];
         }
     }];
}

- (void)postUpdateDidFinishWithData:(NSData *)data
{
    DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    if ([delegate respondsToSelector:@selector(postUpdateDidFinish)])
    {
        [delegate postUpdateDidFinish];
    }
}

- (void)postUpdateDidFailWithError:(NSError *)error
{
	[self requestDidFailWithError:error];
	
	if ([delegate respondsToSelector:@selector(postUpdateDidFailWithError:)])
	{
		[delegate postUpdateDidFailWithError:error];
	}
}

- (void)postRetweet:(NSString *)tweetId withURL:(NSURL *)url;
{
	self.activityAlertView = [[GHActivityAlertView alloc] initWithActivityMessage:@"Posting tweet..."];
	[_activityAlertView startAnimating];
	
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	NSString *postParams =[[NSString alloc] initWithFormat:@"tweetId=%@", tweetId];
	NSString *escapedPostParams = [postParams stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	DLog(@"%@", escapedPostParams);
	
	NSData *postData = [escapedPostParams dataUsingEncoding:NSUTF8StringEncoding];	
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	DLog(@"%@ %@", request, [request allHTTPHeaderFields]);

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [_activityAlertView stopAnimating];
         self.activityAlertView = nil;
         
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             [self postRetweetDidFinishWithData:data];
         }
         else if (error)
         {
             [self postRetweetDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             NSString *msg = nil;
             switch (statusCode)
             {
                 case 412:
                     msg = @"Your account is not connected to Twitter. Please sign in to greenhouse.springsource.org to connect.";
                     break;
                 case 403:
                 default:
                     msg = @"A problem occurred while posting to Twitter. Please verify your account is connected to Twitter.";
                     break;
             }
             
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:msg
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
             [alertView show];
         }
     }];
}

- (void)postRetweetDidFinishWithData:(NSData *)data
{
	DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Retweet successful!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    
    if ([delegate respondsToSelector:@selector(postRetweetDidFinish)])
    {
        [delegate postRetweetDidFinish];
    }
}

- (void)postRetweetDidFailWithError:(NSError *)error
{
	[self requestDidFailWithError:error];
	
	if ([delegate respondsToSelector:@selector(postRetweetDidFailWithError:)])
	{
		[delegate postRetweetDidFailWithError:error];
	}	
}

@end
