#import "SNCellModel.h"
#import "SNTableViewCell.h"
#import "TOInsetGroupedTableView.h"
#import "Utilities.h"

@interface SNSubSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSDictionary <NSString *, NSArray *> *_tableData;
    TOInsetGroupedTableView *_tableView;
    NSArray <NSString *> *_headersList;
    NSString *_identifier;
}
- (instancetype)initWithIdentifier:(NSString *)identifier;
@end
