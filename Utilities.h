#import <UIKit/UIKit.h>
#import <RemoteLog.h> // For debugging

#define PREF_CHANGED_NOTIF "SNMessenger/prefChanged"

BOOL isDarkMode;

static inline NSBundle *SNMessengerBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"SNMessenger" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:@"/Library/Application Support/SNMessenger.bundle"];
    });
    return bundle;
}

static inline NSString *localizedStringForKey(NSString *key) {
    return [SNMessengerBundle() localizedStringForKey:key value:nil table:nil];
}

static inline void showRequireRestartAlert(UIViewController *viewController) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:localizedStringForKey(@"RESTART_MESSAGE") message:localizedStringForKey(@"RESTART_CONFIRM_MESSAGE") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:localizedStringForKey(@"CONFIRM") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:localizedStringForKey(@"CANCEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }]];

    [viewController presentViewController:alert animated:YES completion:nil];
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
    NSString *path = [SNMessengerBundle() pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

static inline UIImage *getTemplateImage(NSString *name) {
    return [getImage(name) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static inline CGFloat colorComponentFrom(NSString *string, NSUInteger start, NSUInteger length) {
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned int hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];

    return hexComponent / 255.0f;
}

static inline UIColor *colorWithHexString(NSString *hexString) {
    NSString *colorString = [hexString uppercaseString];

    CGFloat alpha, red, blue, green = 0.0f;

    // #RGB
    red   = colorComponentFrom(colorString, 1, 2);
    green = colorComponentFrom(colorString, 3, 2);
    blue  = colorComponentFrom(colorString, 5, 2);
    alpha = [hexString length] == 9 ? colorComponentFrom(colorString, 7, 2) : 1.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

static inline BOOL isNotch() {
    return [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom > 0;
}
