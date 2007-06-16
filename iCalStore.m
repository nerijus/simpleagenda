#import <Foundation/Foundation.h>
#import <GNUstepBase/GSXML.h>
#import <ical.h>
#import "iCalStore.h"
#import "UserDefaults.h"
#import "defines.h"

@implementation Event(iCalendar)

- (id)initWithICalComponent:(icalcomponent *)ic
{
  icalproperty *prop;
  icalproperty *pstart;
  icalproperty *pend;
  struct icaltimetype start;
  struct icaltimetype end;
  struct icaldurationtype diff;
  struct icalrecurrencetype rec;
  Date *date;

  [self init];
  prop = icalcomponent_get_first_property(ic, ICAL_SUMMARY_PROPERTY);
  if (!prop) {
    NSLog(@"No summary");
    goto init_error;
  }
  [self setTitle:[NSString stringWithCString:icalproperty_get_summary(prop) encoding:NSUTF8StringEncoding]];

  pstart = icalcomponent_get_first_property(ic, ICAL_DTSTART_PROPERTY);
  if (!pstart) {
    NSLog(@"No start date");
    goto init_error;
  }
  start = icalproperty_get_dtstart(pstart);
  date = [[Date alloc] init];
  [date setDateToTime_t:icaltime_as_timet(start)];
  [self setStartDate:date andConstrain:NO];
  [self setEndDate:date];

  pend = icalcomponent_get_first_property(ic, ICAL_DTEND_PROPERTY);
  if (!pend) {
    prop = icalcomponent_get_first_property(ic, ICAL_DURATION_PROPERTY);
    if (!prop) {
      NSLog(@"No end date and no duration");
      goto init_error;
    }
    diff = icalproperty_get_duration(prop);
  } else {
    end = icalproperty_get_dtend(pend);
    diff = icaltime_subtract(end, start);
  }
  [self setDuration:icaldurationtype_as_int(diff) / 60];

  prop = icalcomponent_get_first_property(ic, ICAL_RRULE_PROPERTY);
  if (prop) {
    rec = icalproperty_get_rrule(prop);
    [date changeYearBy:10];
    switch (rec.freq) {
    case ICAL_DAILY_RECURRENCE:
      [self setInterval:RI_DAILY];
      [self setFrequency:rec.interval];
      [self setEndDate:date];
      break;
    case ICAL_WEEKLY_RECURRENCE:
      [self setInterval:RI_WEEKLY];
      [self setFrequency:rec.interval];
      [self setEndDate:date];
      break;
    case ICAL_MONTHLY_RECURRENCE:
      [self setInterval:RI_MONTHLY];
      [self setFrequency:rec.interval];
      [self setEndDate:date];
      break;
    case ICAL_YEARLY_RECURRENCE:
      [self setInterval:RI_YEARLY];
      [self setFrequency:rec.interval];
      [self setEndDate:date];
      break;
    default:
      NSLog(@"todo");
      break;
    }
  }
  return self;

 init_error:
  NSLog(@"Error creating Event from iCal component");
  [self release];
  return nil;
}

@end


@implementation iCalStore

- (GSXMLNode *)getLastModifiedElement:(GSXMLNode *)node
{
  GSXMLNode *inter;

  while (node) {
    if ([node type] == [GSXMLNode typeFromDescription:@"XML_ELEMENT_NODE"] && 
	[@"getlastmodified" isEqualToString:[node name]])
      return node;
    if ([node firstChild]) {
      inter = [self getLastModifiedElement:[node firstChild]];
      if (inter)
	return inter;
    }
    node = [node next];
  }
  return nil;
}

- (NSDate *)getLastModified
{
  GSXMLParser *parser;
  GSXMLNode *node;
  NSDate *date;
  NSData *data;

  [_url setProperty:@"PROPFIND" forKey:GSHTTPPropertyMethodKey];
  data = [_url resourceDataUsingCache:NO];
  if (data) {
    parser = [GSXMLParser parserWithData:data];
    if ([parser parse]) {
      node = [self getLastModifiedElement:[[parser document] root]];
      date = [NSDate dateWithNaturalLanguageString:[node content]];
      return date;
    }
  }
  return nil;
}

- (BOOL)needsRefresh
{
  NSDate *lm = [self getLastModified];

  if (!_lastModified) {
    if (lm)
      _lastModified = [lm copy];
    return YES;
  }
  if (!lm)
    return YES;
  if ([_lastModified compare:lm] == NSOrderedAscending) {
    [_lastModified release];
    _lastModified = [lm copy];
    return YES;
  }
  return NO;
}

- (BOOL)read
{
  NSData *data;
  NSString *text;
  Event *ev;
  icalcomponent *ic;

  if ([self needsRefresh]) {
    [_url setProperty:@"GET" forKey:GSHTTPPropertyMethodKey];
    data = [_url resourceDataUsingCache:NO];
    if (data) {
      text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      if (text) {
	if (_icomp)
	  icalcomponent_free(_icomp);
	_icomp = icalparser_parse_string([text cStringUsingEncoding:NSUTF8StringEncoding]);
	if (_icomp) {
	  [_set removeAllObjects];
	  for (ic = icalcomponent_get_first_component(_icomp, ICAL_VEVENT_COMPONENT); 
	       ic != NULL; ic = icalcomponent_get_next_component(_icomp, ICAL_VEVENT_COMPONENT)) {
	    ev = [[Event alloc] initWithICalComponent:ic];
	    if (ev)
	      [_set addObject:ev];
	  }
	}
	[_set makeObjectsPerform:@selector(setStore:) withObject:self];
	NSLog(@"iCalStore from %@ : loaded %d appointment(s)", [_url absoluteString], [_set count]);
      } else
	NSLog(@"Couldn't parse data from %@", [_url absoluteString]);
    } else
      NSLog(@"No data read from %@", [_url absoluteString]);
    return YES;
  }
  return NO;
}

- (id)initWithName:(NSString *)name forManager:(id)manager
{
  NSString *location;

  self = [super init];
  if (self) {
    _delegate = manager;
    _params = [NSMutableDictionary new];
    [_params addEntriesFromDictionary:[[UserDefaults sharedInstance] objectForKey:name]];
    _url = [[NSURL alloc] initWithString:[_params objectForKey:ST_URL]];
    if (_url == nil) {
      NSLog(@"%@ isn't a valid url", [_params objectForKey:ST_URL]);
      [self release];
      return nil;
    }
    if ([_url resourceDataUsingCache:NO] == nil) {
      location = [_url propertyForKey:@"Location"];
      if (!location) {
	NSLog(@"Couldn't read data from %@", [_params objectForKey:ST_URL]);
	[self release];
	return nil;
      }
      _url = [_url initWithString:location];
      if (_url)
	NSLog(@"%@ redirected to %@", name, location);
      else {
	NSLog(@"%@ isn't a valid url", location);
	[self release];
	return nil;
      }
    }
    _name = [name copy];
    _modified = NO;
    _lastModified = nil;
    if ([_params objectForKey:ST_RW])
      _writable = [[_params objectForKey:ST_RW] boolValue];
    else
      _writable = NO;
    _set = [[NSMutableSet alloc] initWithCapacity:128];
    if ([_params objectForKey:ST_DISPLAY])
      _displayed = [[_params objectForKey:ST_DISPLAY] boolValue];
    else
      _displayed = YES;
    [self read]; 

    if (![_url isFileURL]) {
      if ([_params objectForKey:ST_REFRESH])
	_minutesBeforeRefresh = [[_params objectForKey:ST_REFRESH] intValue];
      else
	_minutesBeforeRefresh = 60;
      _refreshTimer = [[NSTimer alloc] initWithFireDate:nil
				       interval:_minutesBeforeRefresh * 60
				       target:self selector:@selector(refreshData:) 
				       userInfo:nil repeats:YES];
      [[NSRunLoop currentRunLoop] addTimer:_refreshTimer forMode:NSDefaultRunLoopMode];
    }
  }
  return self;
}

+ (id)storeNamed:(NSString *)name forManager:(id)manager
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()] initWithName:name 
								  forManager:manager]);
}

- (void)dealloc
{
  [_refreshTimer invalidate];
  [self write];
  if (_icomp)
    icalcomponent_free(_icomp);
  [_set release];
  [_url release];
  [_params release];
  [_name release];
  [_lastModified release];
  [super dealloc];
}

- (void)refreshData:(NSTimer *)timer
{
  if ([self read]) {
    if ([_delegate respondsToSelector:@selector(dataChanged:)])
      [_delegate dataChanged:self];
  }
}

- (NSArray *)scheduledAppointmentsFor:(Date *)day
{
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1];
  NSEnumerator *enumerator = [_set objectEnumerator];
  Event *apt;

  while ((apt = [enumerator nextObject])) {
    if ([apt isScheduledForDay:day])
      [array addObject:apt];
  }
  return array;
}

- (void)addAppointment:(Event *)evt
{
}

- (void)delAppointment:(Event *)evt
{
}

- (void)updateAppointment:(Event *)evt
{
}

- (BOOL)contains:(Event *)evt
{
  return NO;
}

- (BOOL)isWritable
{
  return _writable;
}

- (BOOL)modified
{
  return _modified;
}

- (void)write
{
  NSData *data;
  char *text;
  
  if ([self isWritable] && _icomp && _modified) {
    text = icalcomponent_as_ical_string(_icomp);
    data = [NSData dataWithBytes:text length:strlen(text)];
    [_url setProperty:@"PUT" forKey:GSHTTPPropertyMethodKey];
    if ([_url setResourceData:data]) {
      NSLog(@"iCalStore written to %@", [_url absoluteString]);
      _modified = NO;
    }
  }
}

- (NSString *)description
{
  return _name;
}

- (NSColor *)eventColor
{
  NSColor *aColor = nil;
  NSData *theData =[_params objectForKey:ST_COLOR];

  if (theData)
    aColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
  else {
    aColor = [NSColor blueColor];
    [self setEventColor:aColor];
  }
  return aColor;
}

- (void)setEventColor:(NSColor *)color
{
  NSData *data = [NSArchiver archivedDataWithRootObject:color];
  [_params setObject:data forKey:ST_COLOR];
  [[UserDefaults sharedInstance] setObject:_params forKey:_name];
}

- (BOOL)displayed
{
  return _displayed;
}

- (void)setDisplayed:(BOOL)state
{
  _displayed = state;
  [_params setValue:[NSNumber numberWithBool:_displayed] forKey:ST_DISPLAY];
  [[UserDefaults sharedInstance] setObject:_params forKey:_name];
}

@end
