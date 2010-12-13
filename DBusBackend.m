#import <Foundation/Foundation.h>
#import <DBusKit/DBusKit.h>
#import "AlarmBackend.h"
#import "SAAlarm.h"

@protocol Notifications
- (NSArray *)GetCapabilities;
- (NSNumber *)Notify:(NSString *)appname :(uint)replaceid :(NSString *)appicon :(NSString *)summary :(NSString *)body :(NSArray *)actions :(NSDictionary *)hints :(int)expires;
@end

@interface DBusBackend : AlarmBackend
@end

static NSString * const DBUS_BUS = @"org.freedesktop.Notifications";
static NSString * const DBUS_PATH = @"/org/freedesktop/Notifications";

@implementation DBusBackend
+ (NSString *)backendName
{
  return @"DBus desktop notification";
}

- (id)init
{
  NSConnection *c;
  id <NSObject,Notifications> remote;
  NSArray *caps;

  self = [super init];
  if (self) {
    c = [NSConnection connectionWithReceivePort:[DKPort port] sendPort:[[DKPort alloc] initWithRemote:DBUS_BUS]];
    if (!c) {
      NSLog(@"Unable to create a connection to org.freedesktop.Notifications");
      [self release];
      return nil;
    }
    remote = (id <NSObject,Notifications>)[c proxyAtPath:DBUS_PATH];
    if (!remote) {
      NSLog(@"Unable to create a proxy for /org/freedesktop/Notifications");
      [self release];
      return nil;
    }
    caps = [remote GetCapabilities];
    if (!caps) {
      NSLog(@"No response to GetCapabilities method");
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)display:(SAAlarm *)alarm
{
    NSConnection *c;
    NSNumber *dnid;
    id <NSObject,Notifications> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort port] sendPort:[[DKPort alloc] initWithRemote:DBUS_BUS]];
    remote = (id <NSObject,Notifications>)[c proxyAtPath:DBUS_PATH];
    dnid = [remote Notify:@"SimpleAgenda" :0 :@"" :@"Attention !" :@"Il va se passer quelque chose" :[NSArray array] :[NSDictionary dictionary] :-1];
}
@end