//
//  Tweets.h
//  TwitterForFlatSoft
//
//  Created by Renat on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tweets : NSManagedObject

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSNumber * tweetId;

@end
