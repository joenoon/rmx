#import <Foundation/Foundation.h>

@class RACScheduler;

@interface RMXRACHelper : NSObject

+ (RACScheduler *)schedulerWithHighPriority;
+ (RACScheduler *)schedulerWithDefaultPriority;
+ (RACScheduler *)schedulerWithLowPriority;
+ (RACScheduler *)schedulerWithBackgroundPriority;

@end
