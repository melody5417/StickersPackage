//
//  ViewController.m
//  StickersPackage
//
//  Created by Yiqi Wang on 16/5/11.
//  Copyright © 2016年 Yiqi Wang. All rights reserved.
//

#import "ViewController.h"
#import "NSData+Package.h"
#import "SSZipArchive.h"

static const NSString *KProductID = @"productId";
static const NSString *KName = @"name";
static const NSString *KCreateTime = @"createTime";
static const NSString *KDesc = @"desc";
static const NSString *KKeyWords = @"keywords";
static const NSString *KMd5OfPopImage = @"md5OfPopImage";
static const NSString *KMd5OfTitleImage = @"md5OfTitleImage";
static const NSString *KMd5OfPreviewImage = @"md5OfPreviewImage";
static const NSString *KMd5ofZip = @"md5OfZip";
static const NSString *KFeeType = @"feeType";
static const NSString *KPrice = @"price";
static const NSString *KBaseInfo = @"baseInfo";
static const NSString *KAuthorID = @"authorId";
static const NSString *KAuthor = @"author";
static const NSString *KIconInfo = @"iconInfo";
static const NSString *KItemInfo = @"itemInfo";
static const NSString *KMd5 = @"md5";
static const NSString *KOperationInfo = @"operationInfo";
static const NSString *KMinVersion = @"minVersion";
static const NSString *KMaxVersion = @"maxVersion";
static const NSString *KFeatureVersion = @"featureVersion";
static const NSString *KPlatForm = @"platform";
static const NSString *KFreeBeginTime = @"freeBeginTime";
static const NSString *KFreeEndTime = @"freeEndTime";
static const NSString *KFreeExpireTime = @"freeExpireTime";


@interface ViewController ()
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *stickerID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *desc;

@property (weak) IBOutlet NSDatePicker *createTime;

@property (weak) IBOutlet NSTextField *filePathLabel;
@property (weak) IBOutlet NSTextField *checkResultLabel;
@property (weak) IBOutlet NSTextField *packItemJsonResultLabel;
@property (weak) IBOutlet NSTextField *packListJsonResultLabel;

@property (weak) IBOutlet NSButton *checkButton;
@property (weak) IBOutlet NSButton *packageButton;
@property (weak) IBOutlet NSButton *packageListButton;
@end


@implementation ViewController

#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.checkButton setEnabled:NO];
  [self.packageButton setEnabled:NO];
  [self.packageListButton setEnabled:NO];
}

#pragma mark - getter & setter

- (NSUInteger)time {
    NSDate *date = self.createTime.dateValue;
    return [date timeIntervalSince1970];
}

- (NSString *)pathStickersStored {
  // 本地存储贴纸资源的路径
  NSString *folderPath = [NSSearchPathForDirectoriesInDomains
                          (NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
  folderPath = [[folderPath stringByAppendingPathComponent:@"Jietu"]
                stringByAppendingPathComponent:@"stickers"];
  return folderPath;
}

#pragma mark - button action

- (IBAction)openAction:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setPrompt:@"Select"];
  [panel setCanChooseFiles:NO];
  [panel setCanChooseDirectories:YES];
  [panel setAllowsMultipleSelection:NO];
  
  [panel beginWithCompletionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton) {
      NSURL *direcURL = [[panel URLs] objectAtIndex:0];
      self.filePath = direcURL.relativePath;
      [self.filePathLabel setStringValue:self.filePath];
      [self.checkButton setEnabled:YES];
    }
  }];
}

- (IBAction)checkValidAction:(id)sender {
  if ([self isFilePathValid]) {
    [self.packageButton setEnabled:YES];
  }
}

- (IBAction)packageAction:(id)sender {
    //读取contents.json
  if ([self readContentsJson]) {
    
    //打包stickerID.json
    if ([self packageItemJson]) {
      [self.packageListButton setEnabled: YES];
    }
  }
}

- (IBAction)packageListAction:(id)sender {
  //手动把zip压缩
  [self packageListJson];
}

#pragma mark - private

//合法文件路径下需要包括文件：contents title prview pop icon item_%
- (BOOL)isFilePathValid {
  //获取文件list
  NSError *error = nil;
  NSArray *contentsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.filePath error:&error];
  if (error) {
    [self.checkResultLabel setStringValue:[NSString stringWithFormat:@"error : %@",error]];
  }
  
  
  //检查是否存在title.pdf等文件
  NSArray *typeArray = @[@"title.pdf", @"preview.pdf",
                         @"pop.gif", @"icon.pdf", @"contents.json"];
  
  for (NSString *temp in typeArray) {
    if (![contentsArray containsObject:temp]) {
      [self.checkResultLabel setStringValue:[NSString stringWithFormat:@"error : does not contain %@",temp]];
      return NO;
    }
  }
  
  //检查是否存在item等文件
  for (NSString *temp in contentsArray) {
    if ([temp containsString:@"item_"]) {
      [self.checkResultLabel setStringValue:@"合法"];
      return  YES;
    }
  }
  
  return NO;
}

- (BOOL)readContentsJson {
  //加载contents.json
  NSData *jsonData = [NSData dataWithContentsOfFile:[self.filePath stringByAppendingPathComponent:@"contents.json"]];
  if (jsonData) {
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:0
                                                              error:nil];
    if (jsonDic) {
      self.stickerID = [jsonDic objectForKey:@"productId"];
      if (!self.stickerID) {
        [self.packItemJsonResultLabel setStringValue:@"stickerID is nil"];
        return NO;
      }
      
      self.name = [jsonDic objectForKey:@"name"];
      if (!self.name) {
        [self.packItemJsonResultLabel setStringValue:@"name is nil"];
        return  NO;
      }
      
      self.desc = [jsonDic objectForKey:@"description"];
      if (!self.desc) {
        [self.packItemJsonResultLabel setStringValue:@"description is nil"];
        return NO;
      }
      
      return YES;
    }
  }
  return NO;
}

- (BOOL)packageItemJson {
  //创建item文件夹
  NSError *error = nil;
  NSString *filePath = [[self pathStickersStored] stringByAppendingPathComponent:[self stickerID]];
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
  }
  if (error) {
    [self.packItemJsonResultLabel setStringValue:@"Create folder error"];
    return NO;
  }
  
  //写json
  NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
  [itemDic setObject:[self stickerID] forKey:KProductID];
  [itemDic setObject:[self name] forKey:KName];
  
  //baseInfo默认
  NSDictionary *baseInfoDic = @{KKeyWords:@"", KFeeType:@"01",
                                KPrice:@(1), KAuthorID:@"",
                                KAuthor:@""};
  [itemDic setObject:baseInfoDic forKeyedSubscript:KBaseInfo];
  
  //Icon 写入json 同时更新名称copy到文件夹下
  error = nil;
  [[NSFileManager defaultManager] copyItemAtPath:[self.filePath stringByAppendingPathComponent:@"icon.pdf"] toPath:[filePath stringByAppendingPathComponent:@"icon.pdf"] error:&error];
  if(error) {
    [self.packItemJsonResultLabel setStringValue:@"copy icon failed"];
    return NO;
  }
  [itemDic setObject:@{KMd5:@"icon"} forKeyedSubscript:KIconInfo];
  
  //Item 读取 copy 写入json
  NSArray *contentsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.filePath error:&error];
  NSMutableArray *itemInfoArray = [[NSMutableArray alloc] init];
  
  for (NSString *temp in contentsArray) {
    if ([temp containsString:@"item_"]) {
      //copy
      error = nil;
      NSString *itemName = [temp substringWithRange:NSMakeRange(5, 2)] ;
      [[NSFileManager defaultManager] copyItemAtPath:[self.filePath stringByAppendingPathComponent:temp   ] toPath:[filePath stringByAppendingPathComponent:[temp substringFromIndex:5]] error:&error];
      if(error) {
        [self.packItemJsonResultLabel setStringValue:@"copy item file failed"];
        return NO;
      }
      //写入array
      [itemInfoArray addObject:@{KName:itemName, KMd5:itemName}];
    }
  }//for
  [itemDic setObject:itemInfoArray forKey:KItemInfo];
  
  
  //operationInfo默认
  NSDictionary *operationInfoDic = @{KMinVersion : @"2.0.0",
                                     KMaxVersion : @"2.0.0",
                                     KFeatureVersion : @"2.0.0",
                                     KPlatForm: @"00",
                                     KFreeBeginTime : @(0),
                                     KFreeEndTime: @(0),
                                     KFreeExpireTime : @(0)};
  [itemDic setObject:operationInfoDic forKeyedSubscript:KOperationInfo];
  
  
  if ([NSJSONSerialization isValidJSONObject:itemDic])
  {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:itemDic options:NSJSONWritingPrettyPrinted error:&error];
    
    BOOL ret = [jsonData writeToFile:[filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",[self stickerID]]] atomically:YES];
    if (!ret) {
      [self.packItemJsonResultLabel setStringValue:@"stickerID.json write failed"];
      return NO;
    }
      //zip item 有问题 需要手动打包
      //          BOOL ret = [SSZipArchive createZipFileAtPath:[self pathStickersStored]  withContentsOfDirectory:[[self pathStickersStored] stringByAppendingPathComponent:[self stickerID]]];
      //          if (ret) {
      //            NSLog(@"zip item file successfully");
      //          }
    return YES;
  }
  return NO;
}

- (BOOL)packageListJson {
  //写list.json
  NSMutableDictionary *listDic = [[NSMutableDictionary alloc] init];
  [listDic setObject:[self stickerID] forKey:KProductID];
  [listDic setObject:[self name] forKey:KName];
  [listDic setObject:[NSNumber numberWithUnsignedInteger:[self time]] forKey:KCreateTime];
  [listDic setObject:[self desc] forKey:KDesc];
  [listDic setObject:@"" forKey:KKeyWords];
  [listDic setObject:@"01" forKey:KFeeType];
  [listDic setObject:[NSNumber numberWithDouble:0] forKey:KPrice];
  
  
  //popImage
  NSData *popImageData = [NSData dataWithContentsOfFile:[self.filePath stringByAppendingPathComponent:@"pop.gif"]];
  [listDic setObject:[popImageData md5] forKey:KMd5OfPopImage];
  //copy
  NSError *error = nil;
  [[NSFileManager defaultManager] copyItemAtPath:[self.filePath stringByAppendingPathComponent:@"pop.gif"   ] toPath:[[self pathStickersStored] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.gif",[self stickerID],[popImageData md5]]] error:&error];
  if(error) {
    NSLog(@"copy pop  file failed %@", error);
  }
  
  //title
  NSData *titleImageData = [NSData dataWithContentsOfFile:[self.filePath stringByAppendingPathComponent:@"title.pdf"]];
  [listDic setObject:[titleImageData md5] forKey:KMd5OfTitleImage];
  //copy
  error = nil;
  [[NSFileManager defaultManager] copyItemAtPath:[self.filePath stringByAppendingPathComponent:@"title.pdf"   ] toPath:[[self pathStickersStored] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.pdf",[self stickerID],[titleImageData md5]]] error:&error];
  if(error) {
    NSLog(@"copy titleImageData  file failed %@", error);
  }
  
  //preview
  NSData *previewImageData = [NSData dataWithContentsOfFile:[self.filePath stringByAppendingPathComponent:@"preview.pdf"]];
  [listDic setObject:[previewImageData md5] forKey:KMd5OfPreviewImage];
  //copy
  error = nil;
  [[NSFileManager defaultManager] copyItemAtPath:[self.filePath stringByAppendingPathComponent:@"preview.pdf"   ] toPath:[[self pathStickersStored] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.pdf",[self stickerID],[previewImageData md5]]] error:&error];
  if(error) {
    NSLog(@"copy previewImageData  file failed %@", error);
  }
  
  //zip
  NSData *zipData = [NSData dataWithContentsOfFile:[[self pathStickersStored] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.zip",[self stickerID],[self stickerID]]]];
  if (zipData) {
    [listDic setObject:[zipData md5] forKey:KMd5ofZip];
  }
  
  if ([NSJSONSerialization isValidJSONObject:listDic])
  {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:listDic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"json data:%@",json);
    
    BOOL ret = [jsonData writeToFile:[[self pathStickersStored] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/list.json",[self stickerID]]]  atomically:YES];
    if (ret) {
      NSLog(@"list.json write successfully");
    }
  }
  return NO;
}

@end
