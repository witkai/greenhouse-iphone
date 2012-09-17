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
//  GHEvent.m
//  Greenhouse
//
//  Created by Roy Clarkson on 7/8/10.
//

#import "GHEvent.h"

@implementation GHEvent

@synthesize eventId = _eventId;
@synthesize title = _title;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize location = _location;
@synthesize description = _description;
@synthesize name = _name;
@synthesize hashtag = _hashtag;
@synthesize groupName = _groupName;
@synthesize venues = _venues;


- (id)initWithEventId:(NSString *)eventId title:(NSString *)title startTime:(NSDate *)startTime entTime:(NSDate *)endTime location:(NSString *)location description:(NSString *)description name:(NSString *)name hashtag:(NSString *)hashtag groupName:(NSString *)groupName venues:(NSArray *)venues
{
    if (self = [super init])
    {
        self.eventId = eventId;
        self.title = title;
        self.startTime = startTime;
        self.endTime = endTime;
        self.location = location;
        self.description = description;
        self.name = name;
        self.hashtag = hashtag;
        self.groupName = groupName;
        self.venues = venues;
    }
    
    return self;
}

@end
