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
//  VenueRoom.h
//  Greenhouse
//
//  Created by Roy Clarkson on 9/5/12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Venue;

@interface VenueRoom : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * roomId;
@property (nonatomic, retain) NSString * venueId;
@property (nonatomic, retain) Venue *venue;

@end
