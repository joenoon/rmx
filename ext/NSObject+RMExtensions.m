//  This is a pull from BlocksKit, with modifications to accept an NSString,
//  Since we can't send true unique pointers for objects from rubymotion, and
//  we'll rely on sending Symbols from rubymotion which turn into unique strings
//  in objective-c.
// 
//
//  NSObject+AssociatedObjects.m
//  BlocksKit
//

#import "NSObject+RMExtensions.h"
#import <objc/runtime.h>

@implementation NSObject (RMEXTAssociatedObjects)

#pragma mark - Instance Methods

- (void)rmext_associateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)rmext_atomicallyAssociateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

- (void)rmext_associateCopyOfValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)rmext_atomicallyAssociateCopyOfValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_COPY);
}

- (void)rmext_weaklyAssociateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

- (id)rmext_associatedValueForKey:(NSString *)key {
  return objc_getAssociatedObject(self, key);
}

- (void)rmext_removeAllAssociatedObjects {
  objc_removeAssociatedObjects(self);
}

#pragma mark - Class Methods

+ (void)rmext_associateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)rmext_atomicallyAssociateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

+ (void)rmext_associateCopyOfValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (void)rmext_atomicallyAssociateCopyOfValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_COPY);
}

+ (void)rmext_weaklyAssociateValue:(id)value withKey:(NSString *)key {
  objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

+ (id)rmext_associatedValueForKey:(NSString *)key {
  return objc_getAssociatedObject(self, key);
}

+ (void)rmext_removeAllAssociatedObjects {
  objc_removeAssociatedObjects(self);
}

@end
