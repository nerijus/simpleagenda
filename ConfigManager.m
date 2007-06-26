#import <Foundation/Foundation.h>
#import "ConfigManager.h"

@implementation ConfigManager(Private)

- (ConfigManager *)initRoot
{
  self = [super init];
  if (self) {
    _cpkey = [NSMutableDictionary new];
    _dict = [NSMutableDictionary new];
    _defaults = [NSMutableDictionary new];
    [_dict setDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"SimpleAgenda"]];
  }
  return self;
}

@end


@implementation ConfigManager

static ConfigManager *singleton;

- (ConfigManager *)initForKey:(NSString *)key withParent:(ConfigManager *)parent
{
  NSAssert(key != nil, @"ConfigManager initForKey called with nil key");
  self = [super init];
  if (self) {
    _cpkey = [NSMutableDictionary new];
    _dict = [NSMutableDictionary new];
    if (parent == nil)
      parent = [ConfigManager globalConfig];
    [_dict setDictionary:[parent dictionaryForKey:key]];
    ASSIGN(_parent, parent);
    ASSIGN(_key, key);
  }
  return self;
}

+ (ConfigManager *)globalConfig
{
  if (singleton == nil)
    singleton = [[ConfigManager alloc] initRoot];
  return singleton;
}

- (void)dealloc
{
  RELEASE(_key);
  RELEASE(_parent);
  [_defaults release];
  [_dict release];
  [_cpkey release];
  [super dealloc];
}

- (void)notifyListenerForKey:(NSString *)key
{
  NSEnumerator *enumerator;
  NSMutableSet *set, *tmp;
  id <ConfigListener> listener;
  if (key)
    set = [_cpkey objectForKey:key];
  else {
    set = [NSMutableSet new];
    enumerator = [_cpkey objectEnumerator];
    while ((tmp = [enumerator nextObject]))
      [set unionSet:tmp];
  }
  enumerator = [set objectEnumerator];
  while ((listener = [enumerator nextObject]))
    [listener config:self dataDidChangedForKey:key];
  if (!key)
    [set release];
}

- (void)registerDefaults:(NSDictionary *)defaults
{
  [_defaults addEntriesFromDictionary:defaults];
}

- (id)objectForKey:(NSString *)key
{
  id obj = [_dict objectForKey:key];

  if (obj)
    return obj;
  return [_defaults objectForKey:key];
}

- (void)setObject:(id)value forKey:(NSString *)key
{
  [_dict setObject:value forKey:key];
  [self notifyListenerForKey:key];
  if (_parent)
    [_parent setObject:_dict forKey:_key];
  else
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

- (int)integerForKey:(NSString *)key
{
  id object;

  object = [self objectForKey:key];
  if (object != nil && [object isKindOfClass:[NSNumber class]])
    return [object intValue];
  return 0;
}

- (void)setInteger:(int)value forKey:(NSString *)key
{
  [self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
  id object;

  object = [self objectForKey:key];
  if (object != nil && [object isKindOfClass:[NSDictionary class]])
    return object;
  return nil;
}

- (void)setDictionary:(NSDictionary *)dict forKey:(NSString *)key
{
  [self setObject:dict forKey:key];
}

- (void)registerClient:(id <ConfigListener>)client forKey:(NSString*)key
{
  NSAssert(key != nil, @"You have to register for a specific key");
  NSMutableSet *listeners = [_cpkey objectForKey:key];
  if (listeners)
    [listeners addObject:client];
  else
    listeners = [NSMutableSet setWithObject:client];
  [_cpkey setObject:listeners forKey:key];
}

- (void)unregisterClient:(id <ConfigListener>)client forKey:(NSString*)key
{
  NSMutableSet *set = [_cpkey objectForKey:key];
  if (set)
    [set removeObject:client];
}

- (void)unregisterClient:(id <ConfigListener>)client
{
  NSMutableSet *set;
  NSEnumerator *enumerator = [_cpkey objectEnumerator];

  while ((set = [enumerator nextObject]))
    [set removeObject:client];
}

@end
