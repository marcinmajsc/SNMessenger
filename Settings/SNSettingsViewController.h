#import "SNCellModel.h"
#import "SNTableViewCell.h"
#import "TOInsetGroupedTableView.h"
#import "Utilities.h"

@interface SNSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableDictionary *_originalSettings;
    TOInsetGroupedTableView *_tableView;
    NSDictionary *_tableData;
    UILabel *_titleLabel;
}
- (instancetype)init;
@end
