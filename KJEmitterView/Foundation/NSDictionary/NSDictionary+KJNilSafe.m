//
//  NSDictionary+NilSafe.m
//  MoLiao
//
//  Created by 杨科军 on 2018/7/31.
//  Copyright © 2018年 杨科军. All rights reserved.
//

#import "NSDictionary+KJNilSafe.h"
#import <objc/runtime.h>

@implementation NSObject (Swizzling)

+ (BOOL)kj_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel {
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method altMethod = class_getInstanceMethod(self, altSel);
    if (!origMethod || !altMethod) {
        return NO;
    }
    class_addMethod(self, origSel, class_getMethodImplementation(self, origSel), method_getTypeEncoding(origMethod));
    class_addMethod(self, altSel, class_getMethodImplementation(self, altSel), method_getTypeEncoding(altMethod));
    method_exchangeImplementations(class_getInstanceMethod(self, origSel), class_getInstanceMethod(self, altSel));
    return YES;
}

+ (BOOL)kj_swizzleClassMethod:(SEL)origSel withMethod:(SEL)altSel {
    return [object_getClass((id)self) kj_swizzleMethod:origSel withMethod:altSel];
}

@end

@implementation NSDictionary (KJNilSafe)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self kj_swizzleMethod:@selector(initWithObjects:forKeys:count:) withMethod:@selector(kj_initWithObjects:forKeys:count:)];
        [self kj_swizzleClassMethod:@selector(dictionaryWithObjects:forKeys:count:) withMethod:@selector(kj_dictionaryWithObjects:forKeys:count:)];
    });
}

+ (instancetype)kj_dictionaryWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
    id safeObjects[cnt];
    id safeKeys[cnt];
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        id key = keys[i];
        id obj = objects[i];
        if (!key || !obj) {
            continue;
        }
        safeKeys[j] = key;
        safeObjects[j] = obj;
        j++;
    }
    return [self kj_dictionaryWithObjects:safeObjects forKeys:safeKeys count:j];
}

- (instancetype)kj_initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
    id safeObjects[cnt];
    id safeKeys[cnt];
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        id key = keys[i];
        id obj = objects[i];
        if (!key || !obj) {
            continue;
        }
        if (!obj) {
            obj = [NSNull null];
        }
        safeKeys[j] = key;
        safeObjects[j] = obj;
        j++;
    }
    return [self kj_initWithObjects:safeObjects forKeys:safeKeys count:j];
}

@end

@implementation NSMutableDictionary (KJNilSafe)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = NSClassFromString(@"__NSDictionaryM");
        [class kj_swizzleMethod:@selector(setObject:forKey:) withMethod:@selector(kj_setObject:forKey:)];
        [class kj_swizzleMethod:@selector(setObject:forKeyedSubscript:) withMethod:@selector(kj_setObject:forKeyedSubscript:)];
    });
}

- (void)kj_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (!aKey || !anObject) {
        return;
    }
    [self kj_setObject:anObject forKey:aKey];
}

- (void)kj_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (!key || !obj) {
        return;
    }
    [self kj_setObject:obj forKeyedSubscript:key];
}

@end
