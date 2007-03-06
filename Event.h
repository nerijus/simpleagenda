/* emacs buffer mode hint -*- objc -*- */

#import <ChronographerSource/Date.h>
#import <ChronographerSource/Appointment.h>

@interface Event : Appointment
{
  id _store;
  NSString *location;
}

- (id)initWithStartDate:(Date *)start duration:(int)minutes title:(NSString *)aTitle;
- (BOOL)startsBetween:(Date *)start and:(Date *)end;
- (id)store;
- (void)setStore:(id)store;
- (NSString *)location;
- (void)setLocation:(NSString *)aLocation;

@end