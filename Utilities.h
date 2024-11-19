#import <CydiaSubstrate.h>
#import <UIKit/UIKit.h>
#import <RemoteLog.h> // For debugging
#import <rootless.h>
#import <version.h>

#define PREF_CHANGED_NOTIF "SNMessenger/prefChanged"

extern BOOL isDarkMode;
extern NSBundle *tweakBundle;

static inline MSImageRef getImageRef(NSString *framework) {
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/%@", [[NSBundle mainBundle] bundlePath], framework];
    NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
    if (!bundle.loaded) [bundle load];
    return MSGetImageByName([frameworkPath UTF8String]);
}

static inline CGFloat MessengerVersion() {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [[version substringToIndex:5] floatValue];
}

static inline NSString *localizedStringForKey(NSString *key) {
    return [tweakBundle localizedStringForKey:key value:nil table:nil];
}

static inline NSString *getSettingsPlistPath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"SNMessenger.plist"];
    return plistPath;
}

static inline NSMutableDictionary *getCurrentSettings() {
    return [[NSMutableDictionary alloc] initWithContentsOfFile:getSettingsPlistPath()] ?: [@{} mutableCopy];
}

static inline NSMutableDictionary *compareDictionaries(NSDictionary *oldDict, NSDictionary *newDict) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    [newDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id newDictObj, BOOL *stop) {
        id oldDictObj = oldDict[key];

        if (!oldDictObj || ![newDictObj isEqual:oldDictObj]) {
            result[key] = newDictObj;
        }
    }];

    return result;
}

static inline UIImage *getImage(NSString *name) {
    NSString *path = [tweakBundle pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

static inline UIImage *getTemplateImage(NSString *name) {
    return [getImage(name) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static inline UIImage *scaleImageWithSize(UIImage *image, CGSize size) {
    if (!image) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

static inline CGFloat colorComponentFrom(NSString *string, NSUInteger start, NSUInteger length) {
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned int hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];

    return hexComponent / 255.0f;
}

static inline UIColor *colorWithHexString(NSString *hexString) {
    CGFloat Red   = colorComponentFrom(hexString, 1, 2);
    CGFloat Green = colorComponentFrom(hexString, 3, 2);
    CGFloat Blue  = colorComponentFrom(hexString, 5, 2);
    CGFloat Alpha = [hexString length] == 9 ? colorComponentFrom(hexString, 7, 2) : 1.0f;

    return [UIColor colorWithRed:Red green:Green blue:Blue alpha:Alpha];
}
