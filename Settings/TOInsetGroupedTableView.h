// An iOS 12 back-port of the grouped inset table view style in iOS 13.
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import <version.h>
#import "Utilities.h"

@interface TOInsetGroupedTableView : UITableView
@property (nonatomic, assign) NSInteger realSeparatorStyle;
@property (nonatomic, strong) NSMutableSet *observedViews;
- (instancetype)initWithFrame:(CGRect)frame;
@end
