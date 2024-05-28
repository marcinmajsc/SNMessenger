#import "SNCellModel.h"

@implementation SNCellModel

- (SNCellModel *)initWithType:(CellType)type labelKey:(NSString *)labelKey {
    self = [super init];
    self.type = type;
    self.labelKey = labelKey;
    return self;
}

@end
