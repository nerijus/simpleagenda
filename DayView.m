/* emacs buffer mode hint -*- objc -*- */

#import "AgendaStore.h"
#import "DayView.h"
#import "ConfigManager.h"
#import "iCalTree.h"
#import "defines.h"

static NSImage *repeatImage;

#define RedimRect(frame) NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 10)
#define TextRect(rect) NSMakeRect(rect.origin.x + 4, rect.origin.y, rect.size.width - 8, rect.size.height - 2)

@interface AppointmentView : NSView
{
  Event *_apt;
  BOOL _selected;
}
- (Event *)appointment;
- (void)setSelected:(BOOL)selected;
@end

@implementation AppointmentView
- (id)initWithFrame:(NSRect)frameRect appointment:(Event *)apt;
{
  self = [super initWithFrame:frameRect];
  if (self) {
    ASSIGN(_apt, apt);
    _selected = NO;
  }
  return self;
}
- (void)dealloc
{
  RELEASE(_apt);
  [super dealloc];
}
- (BOOL)selected
{
  return _selected;
}
- (void)setSelected:(BOOL)selected
{
  _selected = selected;
}
#define CEC_BORDERSIZE 1
#define RADIUS 5
- (void)drawRect:(NSRect)rect
{
  NSString *title;
  NSString *label;
  Date *start = [_apt startDate];
  NSColor *color = [[_apt store] eventColor];
  NSColor *darkColor = [NSColor colorWithCalibratedRed:[color redComponent] - 0.3
				green:[color greenComponent] - 0.3
				blue:[color blueComponent] - 0.3
				alpha:[color alphaComponent]];
  NSDictionary *textAttributes = [NSDictionary dictionaryWithObject:[[_apt store] textColor]
					       forKey:NSForegroundColorAttributeName];

  if ([_apt allDay])
    title = [NSString stringWithFormat:@"All day : %@", [_apt summary]];
  else
    title = [NSString stringWithFormat:@"%2dh%0.2d : %@", [start hourOfDay], [start minuteOfHour], [_apt summary]];
  if ([_apt text])
    label = [NSString stringWithFormat:@"%@\n\n%@", title, [[_apt text] string]];
  else
    label = [NSString stringWithString:title];

  PSnewpath();
  PSmoveto(RADIUS + CEC_BORDERSIZE, CEC_BORDERSIZE);
  PSrcurveto(-RADIUS, 0, -RADIUS, RADIUS, -RADIUS, RADIUS);
  PSrlineto(0, NSHeight(rect) + rect.origin.y - 2 * (RADIUS + CEC_BORDERSIZE));
  PSrcurveto( 0, RADIUS, RADIUS, RADIUS, RADIUS, RADIUS);
  PSrlineto(NSWidth(rect) - 2 * (RADIUS + CEC_BORDERSIZE),0);
  PSrcurveto( RADIUS, 0, RADIUS, -RADIUS, RADIUS, -RADIUS);
  PSrlineto(0, -NSHeight(rect) - rect.origin.y + 2 * (RADIUS + CEC_BORDERSIZE));
  PSrcurveto(0, -RADIUS, -RADIUS, -RADIUS, -RADIUS, -RADIUS);
  PSclosepath();
  PSgsave();
  [color set];
  PSsetalpha(0.7);
  PSfill();
  PSgrestore();
  if (_selected)
    [[NSColor whiteColor] set];
  else
    [darkColor set];
  PSsetalpha(0.7);
  PSsetlinewidth(CEC_BORDERSIZE);
  PSstroke();
  if (![_apt allDay]) {
    NSRect rd = RedimRect(rect);
    PSnewpath();
    PSmoveto(RADIUS + CEC_BORDERSIZE, rd.origin.y);
    PSrcurveto( -RADIUS, 0, -RADIUS, RADIUS, -RADIUS, RADIUS);
    PSrlineto(0,NSHeight(rd) - 2 * (RADIUS + CEC_BORDERSIZE));
    PSrcurveto( 0, RADIUS, RADIUS, RADIUS, RADIUS, RADIUS);
    PSrlineto(NSWidth(rd) - 2 * (RADIUS + CEC_BORDERSIZE),0);
    PSrcurveto( RADIUS, 0, RADIUS, -RADIUS, RADIUS, -RADIUS);
    PSrlineto(0, -NSHeight(rd) + 2 * (RADIUS + CEC_BORDERSIZE));
    PSrcurveto( 0, -RADIUS, -RADIUS, -RADIUS, -RADIUS, -RADIUS);
    PSclosepath();
    [darkColor set];
    PSsetalpha(0.7);
    PSfill();
  }
  [label drawInRect:TextRect(rect) withAttributes:textAttributes];
  if ([_apt interval] != RI_NONE)
    [repeatImage compositeToPoint:NSMakePoint(rect.size.width - 18, rect.size.height - 18) operation:NSCompositeSourceOver];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  DayView *parent = (DayView *)[self superview];
  id delegate = [parent delegate];
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  int diff;
  int start;
  int minutes;
  BOOL keepOn = YES;
  BOOL modified = NO;
  BOOL inResize;

  if ([theEvent clickCount] > 1) {
    if ([delegate respondsToSelector:@selector(dayView:editEvent:)])
      [delegate dayView:parent editEvent:_apt];
    return;
  }
  [self becomeFirstResponder];
  [parent selectAppointmentView:self];

  if (![[_apt store] writable] || [_apt allDay])
    return;
  inResize = [self mouse:mouseLoc inRect:RedimRect([self bounds])];
  if (inResize) {
    [[NSCursor resizeUpDownCursor] push];
    start = [[_apt startDate] minuteOfDay];
    while (keepOn) {
      theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
      mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:self];

      switch ([theEvent type]) {
      case NSLeftMouseDragged:
	minutes = [parent roundMinutes:[parent positionToMinute:mouseLoc.y] - start];
	if (minutes != [_apt duration]) {
	  [_apt setDuration:minutes];
	  modified = YES;
	  [parent setNeedsDisplay:YES];
	}
	break;
      case NSLeftMouseUp:
	keepOn = NO;
	break;
      default:
	break;
      }
    }
  } else {
    [[NSCursor openHandCursor] push];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:self];
    diff = [parent minuteToPosition:[[_apt startDate] minuteOfDay]] - mouseLoc.y;
    while (keepOn) {
      theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
      mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:self];
      switch ([theEvent type]) {
      case NSLeftMouseDragged:
	minutes = [parent roundMinutes:[parent positionToMinute:mouseLoc.y + diff]];
	if (minutes != [[_apt startDate] minuteOfDay]) {
	  [[_apt startDate] setMinute:minutes];
	  modified = YES;
	  [parent setNeedsDisplay:YES];
	}
	break;
      case NSLeftMouseUp:
	keepOn = NO;
	break;
      default:
	break;
      }
    }
  }
  [NSCursor pop];
  if (modified && [delegate respondsToSelector:@selector(dayView:modifyEvent:)])
    [delegate dayView:parent modifyEvent:_apt];
}
- (Event *)appointment
{
  return _apt;
}
- (BOOL)acceptsFirstResponder
{
  return YES;
}
@end

NSComparisonResult compareAppointmentViews(id a, id b, void *data)
{
  return [[[a appointment] startDate] compareTime:[[b appointment] startDate]];
}

@implementation DayView
- (NSDictionary *)defaults
{
  NSDictionary *dict = [NSDictionary 
			 dictionaryWithObjects:[NSArray arrayWithObjects:@"9", @"18", @"15", nil]
			 forKeys:[NSArray arrayWithObjects:FIRST_HOUR, LAST_HOUR, MIN_STEP, nil]];
  return dict;
}

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self) {
    ConfigManager *config = [ConfigManager globalConfig];
    [config registerDefaults:[self defaults]];
    [config registerClient:self forKey:FIRST_HOUR];
    [config registerClient:self forKey:LAST_HOUR];
    [config registerClient:self forKey:MIN_STEP];

    _firstH = [config integerForKey:FIRST_HOUR];
    _lastH = [config integerForKey:LAST_HOUR];
    _minStep = [config integerForKey:MIN_STEP];
    _textAttributes = [[NSDictionary dictionaryWithObject:[NSColor textColor]
 				     forKey:NSForegroundColorAttributeName] retain];
    _backgroundColor = [[[NSColor controlBackgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    _alternateBackgroundColor = [[NSColor colorWithCalibratedRed:[_backgroundColor redComponent] + 0.05
					 green:[_backgroundColor greenComponent] + 0.05
					 blue:[_backgroundColor blueComponent] + 0.05
					 alpha:[_backgroundColor alphaComponent]] retain];

    if (!repeatImage) {
      NSString *path = [[NSBundle mainBundle] pathForImageResource:@"repeat"];
      repeatImage = [[NSImage alloc] initWithContentsOfFile:path];
      [repeatImage setFlipped:YES];
    }
    [self reloadData];
  }
  return self;
}

- (void)dealloc
{
  [_backgroundColor release];
  [_alternateBackgroundColor release];
  [_textAttributes release];
  [super dealloc];
}

/* FIXME : the following could probably be simplified... */
- (int)_minuteToSize:(int)minutes
{
  return minutes * [self frame].size.height / ((_lastH - _firstH + 1) * 60);
}
- (int)minuteToPosition:(int)minutes
{
  return [self frame].size.height - [self _minuteToSize:minutes - (_firstH * 60)] - 1;
}
- (int)positionToMinute:(float)position
{
  return ((_lastH + 1) * 60) - ((_lastH - _firstH + 1) * 60) * position / [self frame].size.height;
}

- (void)fixFrames
{
  int i, j, k, n;
  NSArray *subviews;
  AppointmentView *view, *next;
  NSRect fview, fnext;
  float width, x;

  subviews = [[self subviews] sortedArrayUsingFunction:compareAppointmentViews context:NULL];
  if ([subviews count] < 2)
    return;
  for (i = 0; i < [subviews count] - 1; i++) {
    view = [subviews objectAtIndex:i];
    fview = [view frame];
    for (j = i + 1, n = 1; j < [subviews count]; j++) {
      next = [subviews objectAtIndex:j];
      fnext = [next frame];
      if (!NSIntersectsRect(fview, fnext))
	break;
      n++;
      fview = NSUnionRect(fview, fnext);
    }
    if (n != 1) {
      width = [view frame].size.width / n;
      x = [view frame].origin.x;
      for (k = i; k < i + n; k++) {
	view = [subviews objectAtIndex:k];
	fview = [view frame];
	fview.size.width = width;
	fview.origin.x = x;
	x += width;
	[view setFrame:fview];
      }
    }
  }
}
- (NSRect)frameForAppointment:(Event *)apt
{
  int size, start;

  if ([apt allDay])
    return NSMakeRect(40, 0, [self frame].size.width - 48, [self frame].size.height);
  start = [self minuteToPosition:[[apt startDate] minuteOfDay]];
  size = [self _minuteToSize:[apt duration]];
  return NSMakeRect(40, start - size, [self frame].size.width - 48, size);
}
- (int)roundMinutes:(int)minutes
{
  int rounded = minutes / _minStep * _minStep;
  return (rounded < _minStep) ? _minStep : rounded;
}

- (void)drawRect:(NSRect)rect
{
  NSSize size;
  NSString *hour;
  AppointmentView *aptv; 
  NSEnumerator *enumerator;
  int h, start;
  int hrow;
  float miny, maxy;

  /* 
   * FIXME : this is ugly and slow, we're doing
   * work when it's not needed and probably twice.
   */
  enumerator = [[self subviews] objectEnumerator];
  while ((aptv = [enumerator nextObject]))
    [aptv setFrame:[self frameForAppointment:[aptv appointment]]];
  [self fixFrames];
  /*
   * FIXME : if we draw the string in the same
   * loop it doesn't appear on the screen.
   */
  hrow = [self _minuteToSize:60];
  for (h = _firstH; h <= _lastH + 1; h++) {
    start = [self minuteToPosition:h * 60];
    if (h % 2)
      [_backgroundColor set];
    else
      [_alternateBackgroundColor set];
    NSRectFill(NSMakeRect(0, start, rect.size.width, hrow + 1));
  }
  for (h = _firstH; h <= _lastH; h++) {
    hour = [NSString stringWithFormat:@"%d h", h];
    start = [self minuteToPosition:h * 60];
    size = [hour sizeWithAttributes:_textAttributes];
    [hour drawAtPoint:NSMakePoint(4, start - hrow / 2 - size.height / 2) withAttributes:_textAttributes];
  }
  if (_startPt.x != _endPt.x && _startPt.y != _endPt.y) {
    miny = MIN(_startPt.y, _endPt.y);
    maxy = MAX(_startPt.y, _endPt.y);
    [[NSColor grayColor] set];
    NSFrameRect(NSMakeRect(40, miny, rect.size.width - 48, maxy - miny));
  }
}

- (id)dataSource
{
  return dataSource;
}
- (void)setDataSource:(id)source
{
  dataSource = source;
}
- (id)delegate
{
  return delegate;
}
- (void)setDelegate:(id)theDelegate
{
  delegate = theDelegate;
}

- (void)selectAppointmentView:(AppointmentView *)aptv
{
  if (_selected != aptv) {
    [_selected setSelected:NO];
    [aptv setSelected:YES];
    [self setNeedsDisplay:YES];
    _selected = aptv;
    if ([delegate respondsToSelector:@selector(dayView:selectEvent:)])
      [delegate dayView:self selectEvent:[aptv appointment]];
  }
}

- (void)reloadData
{
  ConfigManager *config = [ConfigManager globalConfig];
  NSEnumerator *enumerator, *enm;
  AppointmentView *aptv;
  Event *apt;
  NSSet *events;
  BOOL found;

  events = [dataSource scheduledAppointmentsForDay:nil];
  enumerator = [[self subviews] objectEnumerator];
  while ((aptv = [enumerator nextObject])) {
    if (![events containsObject:[aptv appointment]] || ![[[aptv appointment] store] displayed]) {
      if (aptv == _selected)
	_selected = nil;
      [aptv removeFromSuperviewWithoutNeedingDisplay];
      [aptv release];
    }
  }
  enumerator = [events objectEnumerator];
  while ((apt = [enumerator nextObject])) {
    found = NO;
    enm = [[self subviews] objectEnumerator];
    while ((aptv = [enm nextObject])) {
      if ([apt isEqual:[aptv appointment]]) {
	found = YES;
	break;
      }
    }
    if (found == NO) {
      /* FIXME : probably shouldn't be there */
      [config registerClient:self forKey:[[apt store] description]];
      if ([[apt store] displayed])
	[self addSubview:[[AppointmentView alloc] initWithFrame:NSZeroRect appointment:apt]];
    }
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  int start;
  int end;
  BOOL keepOn = YES;
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

  [[self window] makeFirstResponder:self];
  _startPt = _endPt = mouseLoc;
  [[NSCursor crosshairCursor] push];
  while (keepOn) {
    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
    _endPt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    switch ([theEvent type]) {
    case NSLeftMouseUp:
      keepOn = NO;
      break;
    default:
      break;
    }
    [self setNeedsDisplay:YES];
  }
  [NSCursor pop];
  if (ABS(_startPt.y - _endPt.y) > 7 && [self mouse:_endPt inRect:[self bounds]]) {
    start = [self positionToMinute:MAX(_startPt.y, _endPt.y)];
    end = [self positionToMinute:MIN(_startPt.y, _endPt.y)];
    if ([delegate respondsToSelector:@selector(dayView:createEventFrom:to:)])
      [delegate dayView:self createEventFrom:[self roundMinutes:start] to:[self roundMinutes:end]];
  }
  _startPt = _endPt = NSMakePoint(0, 0);
  [self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = 0;

  if ([characters length] > 0)
    character = [characters characterAtIndex: 0];
  
  switch (character) {
  case '\r':
  case NSEnterCharacter: 
    NSLog(@"enter");
    if (_selected != nil) {
      if ([delegate respondsToSelector:@selector(dayView:editEvent:)])
	[delegate dayView:self editEvent:[_selected appointment]];
      return;
    }
  case NSUpArrowFunctionKey:
    [self moveUp:self];
    return;
  case NSDownArrowFunctionKey:
    [self moveDown:self];
    return;
  case NSTabCharacter:
    if (_selected != nil) {
      unsigned int index = [[self subviews] indexOfObject:_selected];
      if (index != NSNotFound) {
	if ([theEvent modifierFlags] & NSShiftKeyMask) {
	  index--;
	  if (index < 0)
	    index = [[self subviews] count] - 1;
	} else {
	  index++;
	  if (index >= [[self subviews] count])
	    index = 0;
	}
	[self selectAppointmentView:[[self subviews] objectAtIndex:index]];
      }
      return;
    }
  }
  [super keyDown:theEvent];
}

- (void)moveUp:(id)sender
{
  if (_selected != nil) {
    [[[_selected appointment] startDate] changeMinuteBy:-_minStep];
    [_selected setFrame:[self frameForAppointment:[_selected appointment]]];
    if ([delegate respondsToSelector:@selector(dayView:modifyEvent:)])
      [delegate dayView:self modifyEvent:[_selected appointment]];
  }
}

- (void)moveDown:(id)sender
{
  if (_selected != nil) {
    [[[_selected appointment] startDate] changeMinuteBy:_minStep];
    [_selected setFrame:[self frameForAppointment:[_selected appointment]]];
    if ([delegate respondsToSelector:@selector(dayView:modifyEvent:)])
      [delegate dayView:self modifyEvent:[_selected appointment]];
  }
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)config:(ConfigManager*)config dataDidChangedForKey:(NSString *)key
{
  _firstH = [config integerForKey:FIRST_HOUR];
  _lastH = [config integerForKey:LAST_HOUR];
  _minStep = [config integerForKey:MIN_STEP];
  [self reloadData];
}

- (int)firstHour
{
  return _firstH;
}
- (int)lastHour
{
  return _lastH;
}
- (int)minimumStep
{
  return _minStep;
}

- (void)deselectAll:(id)sender
{
  if (_selected) {
    [_selected setSelected:NO];
    [self setNeedsDisplay:YES];
    _selected = nil;
  }
}
@end
