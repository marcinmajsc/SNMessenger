#import "Utilities.h"

typedef NS_ENUM(NSUInteger, CellType) {
    Switch,
    Button,
    Link,
    OptionsList,
    Option
};

@interface SNCellModel : NSObject
@property (nonatomic, assign) CellType type;
@property (nonatomic, retain) NSString *prefKey;
@property (nonatomic, retain) NSString *labelKey;
@property (nonatomic, retain) NSString *subtitleKey;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) BOOL defaultValue;
@property (nonatomic, assign) BOOL isRestartRequired;
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, assign) SEL buttonAction;
@property (nonatomic, retain) NSString *titleKey; // only for OptionsList type
@property (nonatomic, retain) NSArray *listOptions; // only for OptionsList type
@property (nonatomic, retain) NSMutableArray *defaultValues; // only for OptionsList type
@property (nonatomic, assign) BOOL isMultipleChoices; // only for OptionsList type
- (instancetype)initWithType:(CellType)type labelKey:(NSString *)labelKey;
@end
