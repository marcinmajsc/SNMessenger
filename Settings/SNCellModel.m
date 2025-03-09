#import "SNCellModel.h"

@implementation SNCellModel

- (SNCellModel *)initWithType:(CellType)type labelKey:(NSString *)labelKey {
    self = [super init];
    self.type = type;
    self.labelKey = labelKey;
    return self;
}

- (NSMutableArray *)getOptionsList {
    if (self.type == OptionsList && self.options) {
        NSMutableArray *optionsList = [@[] mutableCopy];
        for (NSString *labelKey in self.options) {
            SNCellModel *optionModel = [[SNCellModel alloc] initWithType:Option labelKey:labelKey];
            optionModel.prefKey = self.prefKey;
            optionModel.defaultValue = self.defaultValue;
            [optionsList addObject:optionModel];
        }

        return optionsList;
    }

    return nil;
}

@end
