// Copyright 2016-present 650 Industries. All rights reserved.

#import "ABI20_0_0EXRemoteNotificationRequester.h"
#import "ABI20_0_0EXUnversioned.h"

#import <ReactABI20_0_0/ABI20_0_0RCTUtils.h>

@interface ABI20_0_0EXRemoteNotificationRequester ()

@property (nonatomic, strong) ABI20_0_0RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) ABI20_0_0RCTPromiseRejectBlock reject;
@property (nonatomic, weak) id<ABI20_0_0EXPermissionRequesterDelegate> delegate;

@end

@implementation ABI20_0_0EXRemoteNotificationRequester

+ (NSDictionary *)permissions
{
  ABI20_0_0EXPermissionStatus status = (ABI20_0_0RCTSharedApplication().isRegisteredForRemoteNotifications) ?
    ABI20_0_0EXPermissionStatusGranted :
    ABI20_0_0EXPermissionStatusUndetermined;
  return @{
           @"status": [ABI20_0_0EXPermissions permissionStringForStatus:status],
           @"expires": ABI20_0_0EXPermissionExpiresNever,
           };
}

- (void)requestPermissionsWithResolver:(ABI20_0_0RCTPromiseResolveBlock)resolve rejecter:(ABI20_0_0RCTPromiseRejectBlock)reject
{
  _resolve = resolve;
  _reject = reject;
  
  if (ABI20_0_0RCTSharedApplication().isRegisteredForRemoteNotifications) {
    // resolve immediately if already registered
    [self _consumeResolverWithCurrentPermissions];
  } else {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleDidRegisterForRemoteNotifications:)
                                                 name:@"EXAppDidRegisterForRemoteNotificationsNotification"
                                               object:nil];
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    [ABI20_0_0RCTSharedApplication() registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:types categories:nil]];
    [ABI20_0_0RCTSharedApplication() registerForRemoteNotifications];
  }
}

- (void)setDelegate:(id<ABI20_0_0EXPermissionRequesterDelegate>)delegate
{
  _delegate = delegate;
}

- (void)_handleDidRegisterForRemoteNotifications:(__unused NSNotification *)notif
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self _consumeResolverWithCurrentPermissions];
}

- (void)_consumeResolverWithCurrentPermissions
{
  if (_resolve) {
    _resolve([[self class] permissions]);
    _resolve = nil;
    _reject = nil;
  }
  if (_delegate) {
    [_delegate permissionRequesterDidFinish:self];
  }
}

@end
