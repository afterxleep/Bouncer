//
//  SwinjectStoryboard+SetUp.m
//  SwinjectStoryboard
//
//  Created by Mark DiFranco on 2017-05-27.
//  Copyright © 2017 Swinject Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SwinjectStoryboard/SwinjectStoryboardProtocol.h>

#if __has_include(<SwinjectStoryboard/SwinjectStoryboard-Swift.h>)
    #import <SwinjectStoryboard/SwinjectStoryboard-Swift.h>
#elif __has_include("SwinjectStoryboard-Swift.h")
    #import "SwinjectStoryboard-Swift.h"
#endif

@interface SwinjectStoryboard (SetUp)

@end

@implementation SwinjectStoryboard (SetUp)

@end

__attribute__((constructor)) static void swinjectStoryboardSetupEntry(void) {
    if ([SwinjectStoryboard conformsToProtocol:@protocol(SwinjectStoryboardProtocol)] &&
        [SwinjectStoryboard respondsToSelector:@selector(setup)]) {
        [SwinjectStoryboard performSelector:@selector(setup)];
    }
}
