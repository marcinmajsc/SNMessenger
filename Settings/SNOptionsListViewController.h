#import "SNCellModel.h"
#import "SNTableViewCell.h"
#import "TOInsetGroupedTableView.h"
#import "Utilities.h"

@interface SNOptionsListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray <SNCellModel *> *_tableData;
    TOInsetGroupedTableView *_tableView;
    SNCellModel *_optionsListData;
}
- (instancetype)initWithOptionsListData:(SNCellModel *)optionsListData;
@end
