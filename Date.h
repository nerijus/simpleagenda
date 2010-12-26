/* emacs buffer mode hint -*- objc -*- */

#import "config.h"
#import <Foundation/Foundation.h>

@interface Date : NSObject
{
  struct icaltimetype _time;
}

+ (id)now;
+ (id)today;
+ (id)dateWithTimeInterval:(NSTimeInterval)seconds sinceDate:(Date *)refDate;
+ (id)dateWithCalendarDate:(NSCalendarDate *)cd withTime:(BOOL)time;
- (NSCalendarDate *)calendarDate;
- (NSComparisonResult)compare:(id)aDate;
- (NSComparisonResult)compareTime:(id)aTime;
- (int)year;
- (int)monthOfYear;
- (int)hourOfDay;
- (int)secondOfMinute;
- (int)minuteOfHour;
- (int)minuteOfDay;
- (int)dayOfMonth;
- (int)weekday;
- (int)weekOfYear;
- (int)numberOfDaysInMonth;
- (void)setSecondOfMinute:(int)second;
- (void)setMinute:(int)minute;
- (void)setDay:(int)day;
- (void)setMonth:(int)month;
- (void)setYear:(int)year;
- (void)incrementDay;
- (void)changeYearBy:(int)diff;
- (void)changeDayBy:(int)diff;
- (void)changeMinuteBy:(int)diff;
- (NSEnumerator *)enumeratorTo:(Date *)end;
- (BOOL)isDate;
- (void)setIsDate:(BOOL)date;
- (NSTimeInterval)timeIntervalSince1970;
- (NSTimeInterval)timeIntervalSinceDate:(Date *)anotherDate;
- (NSTimeInterval)timeIntervalSinceNow;
- (BOOL)belongsToDay:(Date *)day;
@end

@interface Date(iCalendar)
- (id)initWithICalTime:(struct icaltimetype)time;
- (struct icaltimetype)iCalTime;
@end
