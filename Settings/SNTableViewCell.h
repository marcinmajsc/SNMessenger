#import <notify.h>
#import "SNCellModel.h"
#import "Utilities.h"

@interface SNTableViewCell : UITableViewCell {
    SNCellModel *_cellData;
    NSString *_plistPath;
}
- (instancetype)initWithData:(SNCellModel *)cellData reuseIdentifier:(NSString *)reuseIdentifier;
@end
