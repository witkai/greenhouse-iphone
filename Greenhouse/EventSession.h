//
//  Copyright 2012 the original author or authors.
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
//  EventSession.h
//  Greenhouse
//
//  Created by Roy Clarkson on 9/6/12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event, EventSessionLeader;

@interface EventSession : NSManagedObject

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * information;
@property (nonatomic, retain) NSString * hashtag;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSNumber * leaderCount;
@property (nonatomic, retain) NSString * leaderDisplay;
@property (nonatomic, retain) NSSet *leaders;
@property (nonatomic, retain) Event *event;
@end

@interface EventSession (CoreDataGeneratedAccessors)

- (void)addLeadersObject:(EventSessionLeader *)value;
- (void)removeLeadersObject:(EventSessionLeader *)value;
- (void)addLeaders:(NSSet *)values;
- (void)removeLeaders:(NSSet *)values;

@end
