//
//  NSMutableArray+TestPersons.m
//  FaceppSDK+Demo
//
//  Created by Cong Thanh on 8/24/15.
//  Copyright (c) 2015 Megvii. All rights reserved.
//

#import "NSMutableArray+TestPersons.h"

@implementation NSMutableArray (TestPersons)
+(NSMutableArray*)testPersons:(NSString*)prefixName number:(int)number
{
    NSString *firstName = prefixName;
    if (!firstName || firstName.length==0) {
        firstName = @"Test name";
    }
    NSMutableArray *personNames = [[NSMutableArray alloc]init];
    for (int i=1; i<=number; i++) {
        NSString *perName = [NSString stringWithFormat:@"%@ %d",firstName, i];
        [personNames addObject:perName];
    }
    return personNames;
}
@end
