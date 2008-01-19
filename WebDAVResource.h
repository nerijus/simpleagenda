/* emacs buffer mode hint -*- objc -*- */

#import <Foundation/Foundation.h>
#import <GNUstepBase/GSXML.h>

@interface WebDAVResource : NSObject <NSURLHandleClient>
{
@private
  NSURL *_url;
  Class _handleClass;
  NSLock *_lock;
  BOOL _dataChanged;
  NSURLHandleStatus _status;
  int _httpStatus;
  NSString *_reason;
  NSString *_lastModified;
  NSString *_etag;
  NSString *_location;
  NSString *_user;
  NSString *_password;
  BOOL _debug;
}

- (id)initWithURL:(NSURL *)url;
- (void)setDebug:(BOOL)debug;
- (BOOL)readable;
/* WARNING Destructive */
- (BOOL)writableWithData:(NSData *)data;
- (int)httpStatus;
- (NSString *)reason;
- (NSString *)location;
- (NSURLHandleStatus)status;
- (BOOL)dataChanged;
- (NSURL *)url;
- (NSData *)options;
- (NSData *)getWithAttributes:(NSDictionary *)attributes;
- (NSData *)get;
- (NSData *)put:(NSData *)data;
- (NSData *)put:(NSData *)data attributes:(NSDictionary *)attributes;
- (NSData *)delete;
- (NSData *)deleteWithAttributes:(NSDictionary *)attributes;
- (NSData *)propfind:(NSData *)data;
- (NSData *)propfind:(NSData *)data attributes:(NSDictionary *)attributes;
- (NSArray *)listICalItems;
- (void)updateAttributes;
- (void)setUser:(NSString *)user password:(NSString *)password;
@end

@interface NSURL(SimpleAgenda)
+ (BOOL)stringIsValidURL:(NSString *)string;
+ (NSURL *)URLWithString:(NSString *)string possiblyRelativeToURL:(NSURL *)base;
- (NSURL *)redirection;
@end

@interface GSXMLDocument(SimpleAgenda)
- (GSXMLDocument *)strippedDocument;
@end