#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SwinjectStoryboard.h"
#import "SwinjectStoryboardProtocol.h"
#import "UIStoryboard+Swizzling.h"
#import "_SwinjectStoryboardBase.h"

FOUNDATION_EXPORT double SwinjectStoryboardVersionNumber;
FOUNDATION_EXPORT const unsigned char SwinjectStoryboardVersionString[];

