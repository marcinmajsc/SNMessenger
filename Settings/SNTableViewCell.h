#import "SNCellModel.h"
#import "Utilities.h"
#import <notify.h>

@interface SNTableViewCell : UITableViewCell {
    SNCellModel *_cellData;
    NSString *_plistPath;
}
- (instancetype)initWithData:(SNCellModel *)cellData reuseIdentifier:(NSString *)reuseIdentifier;
@end
