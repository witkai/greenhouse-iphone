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

- (void)fetchCurrentSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate;
- (void)sendRequestForCurrentSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate;

- (void)fetchSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate;
- (void)sendRequestForSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate;

- (NSArray *)fetchSessionsWithEventId:(NSNumber *)eventId;
- (EventSession *)fetchSessionWithNumber:(NSNumber *)number;
- (NSArray *)fetchSessionsWithPredicate:(NSPredicate *)predicate;
- (void)storeSessionsWithEventId:(NSNumber *)eventId json:(NSArray *)sessions;
- (void)deleteSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)date;
- (NSPredicate *)predicateWithEventId:(NSNumber *)eventId date:(NSDate *)date;

- (void)fetchFavoriteSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate;
- (void)sendRequestForFavoriteSessionsByEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate;

- (void)fetchConferenceFavoriteSessionsByEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsConferenceFavoritesDelegate>)delegate;

- (void)updateFavoriteSessionWithEventId:(NSNumber *)eventId sessionNumber:(NSNumber *)sessionNumber delegate:(id<GHEventSessionUpdateFavoriteDelegate>)delegate;
- (void)sendRequestToUpdateFavoriteSessionWithEventId:(NSNumber *)eventId sessionNumber:(NSNumber *)sessionNumber delegate:(id<GHEventSessionUpdateFavoriteDelegate>)delegate;

- (void)rateSession:(NSNumber *)sessionNumber withEventId:(NSNumber *)eventId rating:(NSInteger)rating comment:(NSString *)comment delegate:(id<GHEventSessionRateDelegate>)delegate;

- (EventSession *)fetchSelectedSession;
- (void)setSelectedSession:(EventSession *)session;

@end

