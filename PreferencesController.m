/* emacs buffer mode hint -*- objc -*- */

#import "PreferencesController.h"
#import "HourFormatter.h"
#import "ConfigManager.h"
#import "defines.h"

@implementation PreferencesController

-(id)initWithStoreManager:(StoreManager *)sm
{
  self = [super init];
  if (self) {
    if (![NSBundle loadNibNamed:@"Preferences" owner:self])
      return nil;

    ASSIGN(_sm, sm);
    HourFormatter *formatter = [[[HourFormatter alloc] init] autorelease];
    [[dayStartText cell] setFormatter:formatter];
    [[dayEndText cell] setFormatter:formatter];
    [[minStepText cell] setFormatter:formatter];
  }
  return self;
}

- (void)dealloc
{
  RELEASE(_sm);
  [super dealloc];
}

-(void)showPreferences
{
  NSEnumerator *list = [_sm objectEnumerator];
  id <AgendaStore> aStore;
  ConfigManager *config = [ConfigManager globalConfig];
  int start = [config integerForKey:FIRST_HOUR];
  int end = [config integerForKey:LAST_HOUR];
  int step = [config integerForKey:MIN_STEP];
  NSString *defaultStore = [config objectForKey:ST_DEFAULT];

  [dayStart setIntValue:start];
  [dayEnd setIntValue:end];
  [dayStartText setIntValue:start];
  [dayEndText setIntValue:end];
  [minStep setDoubleValue:step/60.0];
  [minStepText setDoubleValue:step/60.0];

  /* This could be done during init ? */
  [storePopUp removeAllItems];
  while ((aStore = [list nextObject]))
    [storePopUp addItemWithTitle:[aStore description]];
  [storePopUp selectItemAtIndex:0];
  [self selectStore:self];

  list = [_sm objectEnumerator];
  [defaultStorePopUp removeAllItems];
  while ((aStore = [list nextObject])) {
    if ([aStore isWritable])
      [defaultStorePopUp addItemWithTitle:[aStore description]];
  }
  [defaultStorePopUp selectItemWithTitle:defaultStore];
  [panel makeKeyAndOrderFront:self];
}


-(void)selectStore:(id)sender
{
  id <AgendaStore> store = [_sm storeForName:[storePopUp titleOfSelectedItem]];
  [storeColor setColor:[store eventColor]];
  [storeDisplay setState:[store displayed]];
}

-(void)changeColor:(id)sender
{
  NSColor *rgb = [[storeColor color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  id <AgendaStore> store = [_sm storeForName:[storePopUp titleOfSelectedItem]];
  [store setEventColor:rgb];
}

-(void)changeStart:(id)sender
{
  int value = [dayStart intValue];
  if (value != [[ConfigManager globalConfig] integerForKey:FIRST_HOUR]) {
    [dayStartText setIntValue:value];
    [[ConfigManager globalConfig] setInteger:value forKey:FIRST_HOUR];
  }
}

-(void)changeEnd:(id)sender
{
  int value = [dayEnd intValue];
  if (value != [[ConfigManager globalConfig] integerForKey:LAST_HOUR]) {
    [dayEndText setIntValue:value];
    [[ConfigManager globalConfig] setInteger:value forKey:LAST_HOUR];
  }
}

-(void)changeStep:(id)sender
{
  double value = [minStep doubleValue];
  if (value * 60 != [[ConfigManager globalConfig] integerForKey:MIN_STEP]) {
    [minStepText setDoubleValue:value];
    [[ConfigManager globalConfig] setInteger:value * 60 forKey:MIN_STEP];
  }
}

-(void)selectDefaultStore:(id)sender
{
  id <AgendaStore> store = [_sm storeForName:[defaultStorePopUp titleOfSelectedItem]];
  [[ConfigManager globalConfig] setObject:[store description] forKey:ST_DEFAULT];
}

-(void)toggleDisplay:(id)sender
{
  id <AgendaStore> store = [_sm storeForName:[storePopUp titleOfSelectedItem]];
  [store setDisplayed:[storeDisplay state]];
}

@end
