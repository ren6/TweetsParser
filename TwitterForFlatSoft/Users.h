//
//  Users.h
//  TwitterForFlatSoft
//
//  Created by Renat on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Users : NSManagedObject

@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) id userImage;
@property (nonatomic, retain) NSString * userName;

@end
