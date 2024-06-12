// An iOS 12 version of Inset Grouped Table in iOS 13
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import "Utilities.h"

@interface TOInsetGroupedTableView : UITableView
@property (nonatomic, assign) NSInteger realSeparatorStyle;
@property (nonatomic, strong) NSMutableSet *observedViews;
- (instancetype)initWithFrame:(CGRect)frame;
@end
