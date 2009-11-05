/* emacs buffer mode hint -*- objc -*- */

#import "config.h"
#import <Foundation/Foundation.h>
#import "Date.h"

extern NSString *SAActionDisplay;
extern NSString *SAActionEmail;
extern NSString *SAActionProcedure;
extern NSString *SAActionSound;

@interface SAAlarm : NSObject
{
  Date *_absoluteTrigger;
  NSTimeInterval _relativeTrigger;
  NSString *_action;
  NSString *_emailaddress;
  NSString *_sound;
  NSURL *_url;
}

+ (id)alarm;
- (Date *)absoluteTrigger;
- (void)setAbsoluteTrigger:(Date *)trigger;
- (NSTimeInterval)relativeTrigger;
- (void)setRelativeTrigger:(NSTimeInterval)trigger;
- (NSString *)action;
- (void)setAction:(NSString *)action;
- (NSString *)emailAddress;
- (void)setEmailAddress:(NSString *)emailAddress;
- (NSString *)sound;
- (void)setSound:(NSString *)sound;
- (NSURL *)url;
- (void)setUrl:(NSURL *)url;
- (Date *)triggerDateRelativeTo:(Date *)date;
@end
