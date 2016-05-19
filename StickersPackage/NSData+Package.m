//
//  NSData+Capture.m
//  Jietu
//
//  Created by Yiqi Wang on 16/4/5.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "NSData+Package.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (Capture)

- (NSString*)md5 {
  if (self && self.length > 0) {
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
      [output appendFormat:@"%02x", md5Buffer[i]];
    
    return output;
  }
  return nil;
}

@end
