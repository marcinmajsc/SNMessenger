#import "MSGModel.h"
#import "MSGNavigationCoordinator_LSNavigationCoordinatorProxy.h"

#pragma mark - Settings page

@interface MSGInboxFolderListItemInfoFolder : MSGModel
@end

@interface LSTableViewCellConfig : MSGModel
@end

#pragma mark - Audio / Video call confirmation

@interface LSRTCCallIntent : MSGModel
- (MSGNavigationCoordinator_LSNavigationCoordinatorProxy *)navigationCoordinator;
@end

@interface LSRTCCallIntentValidatorParams : MSGModel
- (LSRTCCallIntent *)callIntent;
@end

#pragma mark - Disable stories preview

@interface MSGStoryCardToolbox : MSGModel
@end

#pragma mark - Extend story video upload duration

@interface MSGMediaVideoPhasset : MSGModel
- (id)asset;
@end

#pragma mark - Hide notification badges in chat top bar | Keyboard state after entering chat

@interface MSGThreadViewOptions : MSGModel
@end

@interface LSImpressionTrackingParameters : MSGModel
- (NSString *)actionName;
@end

@interface MSGThreadViewControllerOptions : MSGModel
- (MSGThreadViewOptions *)viewOptions;
@end

#pragma mark - Hide tabs in tab bar

@interface MDSTabBarItemProps : MSGModel
- (NSString *)accessibilityIdentifierText;
@end

@interface MSGTabBarItemInfo : MSGModel
- (MDSTabBarItemProps *)props;
@end

#pragma mark - Remove ads

@interface MSGThreadListUnitsSate : MSGModel
- (NSMutableDictionary *)unitKeyToUnit;
@end

@interface MSGInboxUnitPositionInThreadList : MSGModel
- (NSInteger)belowThreadIndex;
@end

@interface MSGInboxUnit : MSGModel
- (MSGInboxUnitPositionInThreadList *)positionInThreadList;
@end

@interface MSGStoryViewerBucketModel : MSGModel
- (int)bucketType;
@end

#pragma mark - Hide notes row | Hide search bar

@interface MSGThreadListConfig : MSGModel
@end

#pragma mark - Save friends' stories

@interface MSGStoryViewerOverflowMenuActionTypeSave : MSGModel
@end

@interface MSGStoryOverlayProfileViewActionStandard : MSGModel
@end
