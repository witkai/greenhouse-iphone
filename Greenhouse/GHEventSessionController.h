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
//  GHEventSessionController.h
//  Greenhouse
//
//  Created by Roy Clarkson on 9/7/10.
//

#import "GHBaseController.h"
#import "EventSession.h"
#import "GHEventSessionsByDateDelegate.h"
#import "GHEventSessionsCurrentDelegate.h"
#import "GHEventSessionUpdateFavoriteDelegate.h"
#import "GHEventSessionRateDelegate.h"
#import "GHEventSessionsFavoritesDelegate.h"
#import "GHEventSessionsConferenceFavoritesDelegate.h"


@interface GHEventSessionController : GHBaseController

+ (GHEventSessionController *)sharedInstance;
+ (BOOL)shouldRefreshFavorites;

- (void)fetchCurrentSessionsWithEventId:(NSString *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate;
- (void)sendRequestForCurrentSessionsWithEventId:(NSString *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate;
//- (void)fetchCurrentSessionsDidFinishWithResults:(NSArray *)sessions;
//- (void)fetchCurrentSessionsDidFailWithError:(NSError *)error;

- (void)fetchSessionsWithEventId:(NSString *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate;
- (void)sendRequestForSessionsWithEventId:(NSString *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate;
- (NSArray *)fetchSessionsWithPredicate:(NSPredicate *)predicate;
- (void)storeSessionsWithEventId:(NSString *)eventId json:(NSArray *)sessions;
- (void)deleteSessionsWithEventId:(NSString *)eventId date:(NSDate *)date;
- (NSPredicate *)predicateWithEventId:(NSString *)eventId date:(NSDate *)date;
//- (void)fetchSessionsDidFinishWithResults:(NSArray *)sessions;
//- (void)fetchSessionsDidFailWithError:(NSError *)error;

- (void)fetchFavoriteSessionsWithEventId:(NSString *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate;
- (void)sendRequestForFavoriteSessionsByEventId:(NSString *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate;
//- (void)fetchFavoriteSessionsDidFinishWithResults:(NSArray *)sessions;
//- (void)fetchFavoriteSessionsDidFailWithError:(NSError *)error;

- (void)fetchConferenceFavoriteSessionsByEventId:(NSString *)eventId delegate:(id<GHEventSessionsConferenceFavoritesDelegate>)delegate;
//- (void)fetchConferenceFavoriteSessionsDidFinishWithData:(NSData *)data;
//- (void)fetchConferenceFavoriteSessionsDidFailWithError:(NSError *)error;

- (void)updateFavoriteSessionWithEventId:(NSString *)eventId sessionNumber:(NSString *)sessionNumber delegate:(id<GHEventSessionUpdateFavoriteDelegate>)delegate;
//- (void)updateFavoriteSessionDidFinishWithData:(NSData *)data;
//- (void)updateFavoriteSessionDidFailWithError:(NSError *)error;

- (void)rateSession:(NSString *)sessionNumber withEventId:(NSString *)eventId rating:(NSInteger)rating comment:(NSString *)comment delegate:(id<GHEventSessionRateDelegate>)delegate;
//- (void)rateSessionDidFinishWithData:(NSData *)data;
//- (void)rateSessionDidFailWithError:(NSError *)error;

- (EventSession *)fetchSelectedSession;
- (void)setSelectedSession:(EventSession *)session;

@end

