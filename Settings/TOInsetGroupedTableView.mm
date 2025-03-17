// An iOS 12 version of Inset Grouped Table in iOS 13
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import "TOInsetGroupedTableView.h"

static NSString * const kTOInsetGroupedTableViewFrame = @"frame";
static NSString * const kTOInsetGroupedTableCellSelected = @"selected";

@implementation TOInsetGroupedTableView

#pragma mark - View Life-cycle -

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame style:UITableViewStyleGrouped]) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    self.observedViews = [NSMutableSet set];

    // Disable auto insetting
    self.insetsLayoutMarginsFromSafeArea = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.backgroundColor = colorWithHexString(isDarkMode ? @"#000000" : @"#F5F5F5");

    // Resize the table view to fit its superview
    self.frame = self.superview.bounds;
}

- (void)dealloc {
    [self removeAllObservers];
}

#pragma mark - Table View Behaviour Overrides -

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];

    if ([subview isKindOfClass:[UITableViewHeaderFooterView class]] || [subview isKindOfClass:[UITableViewCell class]]) {
        [self addObserverIfNeeded:subview];
    }
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)separatorStyle {
    if (separatorStyle == UITableViewCellSeparatorStyleNone) {
        // Make sure there will be _UITableViewCellSeparatorView in cell's subViews
        self.separatorColor = [UIColor clearColor];
        self.realSeparatorStyle = UITableViewCellSeparatorStyleNone;
        return;
    }

    self.realSeparatorStyle = -1;
    [super setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (UITableViewCellSeparatorStyle)separatorStyle {
    return self.realSeparatorStyle > -1 ? (UITableViewCellSeparatorStyle)self.realSeparatorStyle : [super separatorStyle];
}

#pragma mark - Observer Life-cycle -

- (void)addObserverIfNeeded:(UIView *)view {
    if ([view isKindOfClass:[UIView class]] && ![self.observedViews containsObject:view]) {
        [view addObserver:self forKeyPath:kTOInsetGroupedTableViewFrame options:0 context:nil];

        if ([view isKindOfClass:[UITableViewCell class]]) {
            [view addObserver:self forKeyPath:kTOInsetGroupedTableCellSelected options:0 context:nil];
        }

        [self.observedViews addObject:view];
    }
}

- (void)removeAllObservers {
    for (UIView *view in self.observedViews) {
        [view removeObserver:self forKeyPath:kTOInsetGroupedTableViewFrame context:nil];

        if ([view isKindOfClass:[UITableViewCell class]]) {
            [view removeObserver:self forKeyPath:kTOInsetGroupedTableCellSelected context:nil];
        }
    }

    [self.observedViews removeAllObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(UIView *)view change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kTOInsetGroupedTableViewFrame]) {
        [self performInsetLayoutForView:view];
    } else if ([keyPath isEqualToString:kTOInsetGroupedTableCellSelected]) {
        [self applyRoundedCornersToTableViewCell:(UITableViewCell *)view];
    }
}

#pragma mark - Behaviour Overrides -

- (void)performInsetLayoutForView:(UIView *)view {
    CGRect frame = [view frame];
    UIEdgeInsets margins = self.layoutMargins;
    UIEdgeInsets safeAreaInsets = self.safeAreaInsets;

    // Calculate the left margin.
    // If the margin < the safe area inset, combine both
    CGFloat leftInset = margins.left;
    if (leftInset - safeAreaInsets.left < 0.0f - FLT_EPSILON) {
        leftInset += safeAreaInsets.left;
    }

    // Calculate the right margin with the same logic
    CGFloat rightInset = margins.right;
    if (rightInset - safeAreaInsets.right < 0.0f - FLT_EPSILON) {
        rightInset += safeAreaInsets.right;
    }

    // Calculate offset and width off the insets
    frame.origin.x = leftInset;
    frame.size.width = CGRectGetWidth([self frame]) - (leftInset + rightInset);

    // Apply the new frame value to the underlying CALayer
    // to avoid triggering the KVO observer into an infinite loop
    view.layer.frame = frame;
}

- (void)applyRoundedCornersToTableViewCell:(UITableViewCell *)cell {
    // Set the cell to always mask its child content
    cell.layer.masksToBounds = YES;

    // Set flags for checking both top and bottom
    BOOL topRounded = NO;
    BOOL bottomRounded = NO;

    // Force a re-layout beforehand
    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    for (UIView *subview in cell.subviews) {
        CGRect frame = [subview frame];

        // Separators will always be less than 1 point high
        if (frame.size.height > 1.0f) {
            continue;
        }

        // If the X origin isn't 0, it's a separator we want to keep.
        // Since it may have been a border separator we hid before, un-hide it.
        if (frame.origin.x > FLT_EPSILON) {
            subview.hidden = NO;
            continue;
        }

        // Check if it's a top or bottom separator
        if (frame.origin.y < FLT_EPSILON) {
            topRounded = YES;
        } else {
            bottomRounded = YES;
        }

        // Hide this view to get a clean looking border
        subview.hidden = YES;
    }

    BOOL needsRounding = (topRounded || bottomRounded);

    // Set the corner radius as needed
    cell.layer.cornerRadius = needsRounding ? 10.0f : 0.0f;

    // Set which corners need to be rounded depending on top or bottom
    NSUInteger cornerRoundingFlags = 0;
    if (topRounded) {
        cornerRoundingFlags |= (kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner);
    }

    if (bottomRounded) {
        cornerRoundingFlags |= (kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
    }

    cell.layer.maskedCorners = cornerRoundingFlags;
}

@end
