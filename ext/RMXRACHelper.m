#import "RMXRACHelper.h"
#import "RACScheduler.h"

@implementation RMXRACHelper

+ (RACScheduler *)schedulerWithHighPriority {
  return [RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh];
}

+ (RACScheduler *)schedulerWithDefaultPriority {
  return [RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault];
}

+ (RACScheduler *)schedulerWithLowPriority {
  return [RACScheduler schedulerWithPriority:RACSchedulerPriorityLow];
}

+ (RACScheduler *)schedulerWithBackgroundPriority {
  return [RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground];
}

@end
