#import "Utilities.h"

typedef NS_ENUM(NSUInteger, CellType) {
    Link,
    Option,
    OptionsList,
    Switch,
};

@interface SNCellModel : NSObject
@property (nonatomic, assign) CellType type;
@property (nonatomic, retain) NSString *prefKey;
@property (nonatomic, retain) NSString *labelKey;
@property (nonatomic, retain) NSString *subtitleKey;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *titleKey;
@property (nonatomic, retain) NSArray *listOptions;
@property (nonatomic, assign) SEL buttonAction;
@property (nonatomic, assign) id defaultValue;
@property (nonatomic, assign) BOOL isRestartRequired;
@property (nonatomic, assign) BOOL disabled;
- (instancetype)initWithType:(CellType)type labelKey:(NSString *)labelKey;
@end
