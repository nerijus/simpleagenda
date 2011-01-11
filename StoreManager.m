#import <Foundation/Foundation.h>
#import "AgendaStore.h"
#import "StoreManager.h"
#import "ConfigManager.h"
#import "defines.h"
#import "Event.h"

NSString * const SADataChangedInStoreManager = @"SADataDidChangedInStoreManager";
static NSString * const PERSONAL_AGENDA = @"Personal Agenda";

static NSMutableDictionary *backends;
static StoreManager *singleton;

@implementation StoreManager
+ (void)initialize
{
  NSArray *classes;
  NSEnumerator *enumerator;
  Class backendClass;

  if ([StoreManager class] == self) {
    classes = GSObjCAllSubclassesOfClass([MemoryStore class]);
    enumerator = [classes objectEnumerator];
    backends = [[NSMutableDictionary alloc] initWithCapacity:[classes count]];
    while ((backendClass = [enumerator nextObject])) {
      if ([backendClass conformsToProtocol:@protocol(MemoryStore)])
	[backends setObject:backendClass forKey:[backendClass storeTypeName]];
      else
	NSLog(@"Can't register %@ as a store backend", [backendClass description]);
    }
    singleton = [[StoreManager alloc] init];
  }
}

+ (NSArray *)backends
{
  return [backends allValues];
}

+ (Class)backendForName:(NSString *)name
{
  return [backends valueForKey:name];
}

+ (StoreManager *)globalManager
{
  return singleton;
}

- (NSDictionary *)defaults
{
  NSDictionary *local = [NSDictionary
			  dictionaryWithObjects:[NSArray arrayWithObjects:@"LocalStore", @"Personal", nil]
			  forKeys:[NSArray arrayWithObjects:ST_CLASS, ST_FILE, nil]];
  NSDictionary *dict = [NSDictionary 
			 dictionaryWithObjects:[NSArray arrayWithObjects: [NSArray arrayWithObject:PERSONAL_AGENDA], local, PERSONAL_AGENDA, nil]
			 forKeys:[NSArray arrayWithObjects: STORES, PERSONAL_AGENDA, ST_DEFAULT, nil]];
  return dict;
}

- (id)init
{
  NSArray *storeArray;
  NSString *defaultStore;
  NSEnumerator *enumerator;
  NSString *stname;
  Class backendClass;
  ConfigManager *config = [ConfigManager globalConfig];
  id store;

  if ((self = [super init])) {
    [config registerDefaults:[self defaults]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(dataChanged:)
					         name:SADataChangedInStore
					       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(dataChanged:)
					         name:SAElementAddedToStore
					       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(dataChanged:)
					         name:SAElementRemovedFromStore
					       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(dataChanged:)
					         name:SAElementUpdatedInStore
					       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(dataChanged:)
					         name:SAEnabledStatusChangedForStore
					       object:nil];
    _stores = [[NSMutableDictionary alloc] initWithCapacity:1];
    _dayEventsCache = [[NSMutableDictionary alloc] initWithCapacity:256];
    _eventCache = [[NSMutableArray alloc] initWithCapacity:512];
    /* Create user defined stores */
    storeArray = [config objectForKey:STORES];
    defaultStore = [config objectForKey:ST_DEFAULT];
    enumerator = [storeArray objectEnumerator];
    while ((stname = [enumerator nextObject]))
      [self addStoreNamed:stname];
    /* Create automatic stores */
    enumerator = [backends objectEnumerator];
    while ((backendClass = [enumerator nextObject])) {
      if (![backendClass isUserInstanciable] && [backendClass storeName]) {
	store = [backendClass storeNamed:[backendClass storeName]];
	[_stores setObject:store forKey:[backendClass storeName]];
	NSLog(@"Added %@ to StoreManager", [backendClass storeName]);
      }
    }
    [self setDefaultStore:defaultStore];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self synchronise];
  RELEASE(_defaultStore);
  RELEASE(_stores);
  RELEASE(_dayEventsCache);
  RELEASE(_eventCache);
  [super dealloc];
}

- (void)dataChanged:(NSNotification *)not
{
  [_dayEventsCache removeAllObjects];
  [_eventCache removeAllObjects];
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStoreManager object:self];
}

- (void)addStoreNamed:(NSString *)name
{
  Class storeClass;
  id <AgendaStore> store;
  NSDictionary *dict;

  dict = [[ConfigManager globalConfig] objectForKey:name];
  if (dict) {
    storeClass = NSClassFromString([dict objectForKey:ST_CLASS]);
    store = [storeClass storeNamed:name];
    if (store) {
      [_stores setObject:store forKey:name];
      NSLog(@"Added %@ to StoreManager", name);
    } else {
      NSLog(@"Unable to initialize store %@", name);
    }
  }
}

- (void)removeStoreNamed:(NSString *)name
{
  [_stores removeObjectForKey:name];
  NSLog(@"Removed %@ from StoreManager", name);
  [self dataChanged:nil];
}

- (id <AgendaStore>)storeForName:(NSString *)name
{
  return [_stores objectForKey:name];
}

- (void)setDefaultStore:(NSString *)name
{
  id st = [self storeForName:name];
  if (st != nil) {
    ASSIGN(_defaultStore, st);
    [[ConfigManager globalConfig] setObject:name forKey:ST_DEFAULT];
  }
}

- (id <AgendaStore>)defaultStore
{
  return _defaultStore;
}

- (NSEnumerator *)storeEnumerator
{
  return [_stores objectEnumerator];
}

- (void)synchronise
{
  NSEnumerator *enumerator = [_stores objectEnumerator];
  id <AgendaStore> store;

  while ((store = [enumerator nextObject]))
    if ([store conformsToProtocol:@protocol(StoreBackend)])
      [store write];
}

- (void)refresh
{
  NSEnumerator *enumerator = [_stores objectEnumerator];
  id <AgendaStore> store;

  while ((store = [enumerator nextObject]))
    [store read];
}

- (id <AgendaStore>)storeContainingElement:(Element *)elt
{
  NSEnumerator *enumerator = [_stores objectEnumerator];
  id <AgendaStore> store;

  while ((store = [enumerator nextObject]))
    if ([store contains:elt])
      return store;
  return nil;
}

- (NSArray *)allEvents
{
  NSEnumerator *enumerator;
  id <AgendaStore> store;

  if ([_eventCache count])
    return _eventCache;
  enumerator = [_stores objectEnumerator];
  while ((store = [enumerator nextObject]))
    if ([store enabled])
      [_eventCache addObjectsFromArray:[store events]];
  return _eventCache;
}

- (NSArray *)allTasks
{
  NSMutableArray *all = [NSMutableArray arrayWithCapacity:32];
  NSEnumerator *enumerator = [_stores objectEnumerator];
  id <AgendaStore> store;

  while ((store = [enumerator nextObject]))
    if ([store enabled])
      [all addObjectsFromArray:[store tasks]];
  return all;
}

- (NSArray *)visibleTasks
{
  NSMutableArray *all = [NSMutableArray arrayWithCapacity:32];
  NSEnumerator *enumerator = [_stores objectEnumerator];
  id <AgendaStore> store;

  while ((store = [enumerator nextObject]))
    if ([store enabled] && [store displayed])
      [all addObjectsFromArray:[store tasks]];
  return all;
}

- (NSSet *)scheduledAppointmentsForDay:(Date *)date
{
  NSMutableSet *dayEvents;
  NSEnumerator *enumerator;
  Event *event;

  NSAssert(date != nil, @"No date specified, am I supposed to guess ?");
  dayEvents = [_dayEventsCache objectForKey:date];
  if (dayEvents)
    return dayEvents;

  dayEvents = [NSMutableSet setWithCapacity:8];
  enumerator = [[self allEvents] objectEnumerator];
  while ((event = [enumerator nextObject]))
    if ([event isScheduledForDay:date])
      [dayEvents addObject:event];
  [_dayEventsCache setObject:dayEvents forKey:date];
  return dayEvents;
}

- (NSSet *)visibleAppointmentsForDay:(Date *)date
{
  NSMutableSet *visible = [NSMutableSet setWithCapacity:4];
  NSEnumerator *enumerator;
  Event *event;

  enumerator = [[self scheduledAppointmentsForDay:date] objectEnumerator];
  while ((event = [enumerator nextObject])) {
    if ([[event store] displayed])
      [visible addObject:event];
  }
  return visible;
}
@end
