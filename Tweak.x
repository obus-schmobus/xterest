#import <UIKit/UIKit.h>

// --- Forward declarations ---

@interface PINPinNode : NSObject
@end

@interface DisplayAttributes : NSObject
- (int)pinType;
@end

@interface PIPin : NSObject
- (BOOL)isPromoted;
- (BOOL)isPromotedPin;
- (BOOL)isThirdPartyAd;
- (BOOL)isSponsored;
- (BOOL)isActiveAd;
- (BOOL)isShoppingAd;
- (BOOL)isSubtleAd;
- (BOOL)isAdsOnly;
- (BOOL)isAdsOnlyRP;
- (BOOL)isDownstreamPromotion;
@end

@interface PINPinCloseupPinPromotionNode : NSObject
@end

@interface PINPagerNode : NSObject
- (NSInteger)currentPageIndex;
- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated;
@end

@interface PINModelCollection : NSObject
- (id)objectAtIndex:(NSInteger)index;
- (NSInteger)count;
@end

@interface PINPinCloseupGalleryViewController : UIViewController
@end

@interface PINPinCloseupSponsorshipNode : NSObject
@end

@interface PINPinCloseupAbovePromotedSeparatorNode : NSObject
@end

@interface PINPinCloseupAdCloseupRPSourceNode : NSObject
@end

@interface PISearchRequestParameters : NSObject
- (BOOL)enablePromotedPins;
@end

@interface PINSearchResultsViewController : UIViewController
@end

@interface PIContentInteractionHandler : NSObject
@end

@interface PIDynamicInsertionPayloadAPIController : NSObject
@end

// Returns YES if the pin object is any kind of ad/promoted content
static BOOL isPinPromoted(id pin) {
    if (!pin) return NO;
    if ([pin respondsToSelector:@selector(isPromoted)] && [pin isPromoted]) return YES;
    if ([pin respondsToSelector:@selector(isPromotedPin)] && [pin isPromotedPin]) return YES;
    if ([pin respondsToSelector:@selector(isThirdPartyAd)] && [pin isThirdPartyAd]) return YES;
    if ([pin respondsToSelector:@selector(isSponsored)] && [pin isSponsored]) return YES;
    if ([pin respondsToSelector:@selector(isActiveAd)] && [pin isActiveAd]) return YES;
    if ([pin respondsToSelector:@selector(isShoppingAd)] && [pin isShoppingAd]) return YES;
    if ([pin respondsToSelector:@selector(isSubtleAd)] && [pin isSubtleAd]) return YES;
    if ([pin respondsToSelector:@selector(isDownstreamPromotion)] && [pin isDownstreamPromotion]) return YES;
    return NO;
}

// ======= Layer 1: Grid — drop promoted pin nodes entirely =======
%hook PINPinNode
- (id)initWithPin:(id)pin displayAttributes:(DisplayAttributes *)attributes {
    if ([attributes pinType] == 2) return nil;
    if (isPinPromoted(pin)) return nil;
    return %orig;
}
%end

// ======= Layer 2: Sideswipe — auto-skip promoted pins in closeup gallery =======
//
// We cannot filter promoted pins from the pager's data source without breaking
// index mapping and swiping. Instead, after each swipe completes, we check if
// the landed-on page is a promoted pin and auto-advance past it.
//
// Uses _pinsFilter (PINModelCollection) to get the pin model at the current index,
// and _pagerNode (PINPagerNode) to scroll programmatically.

%hook PINPinCloseupGalleryViewController
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    %orig;

    PINPagerNode *pager = nil;
    PINModelCollection *filter = nil;
    @try {
        pager = [self valueForKey:@"_pagerNode"];
        filter = [self valueForKey:@"_pinsFilter"];
    } @catch (NSException *e) {
        return;
    }
    if (!pager || !filter) return;

    NSInteger idx = [pager currentPageIndex];
    NSInteger total = [filter count];
    if (idx < 0 || idx >= total) return;

    id pin = [filter objectAtIndex:idx];
    if (!isPinPromoted(pin)) return;

    // Find next non-promoted pin in swipe direction (prefer forward, fallback backward)
    for (NSInteger i = idx + 1; i < total; i++) {
        id candidate = [filter objectAtIndex:i];
        if (!isPinPromoted(candidate)) {
            [pager scrollToPageAtIndex:i animated:YES];
            return;
        }
    }
    // Fallback: try backward
    for (NSInteger i = idx - 1; i >= 0; i--) {
        id candidate = [filter objectAtIndex:i];
        if (!isPinPromoted(candidate)) {
            [pager scrollToPageAtIndex:i animated:YES];
            return;
        }
    }
}
%end

// ======= Layer 3: PIPin model-level ad suppression =======
// - isAdsOnly/isAdsOnlyRP: prevents ad-only feed sections from rendering
%hook PIPin
- (BOOL)isAdsOnly { return NO; }
- (BOOL)isAdsOnlyRP { return NO; }
%end

// ======= Layer 4: Ad-specific closeup UI nodes =======
// Collapse ad-related UI nodes to zero size without breaking the Texture node tree.

%hook PINPinCloseupPinPromotionNode
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize {
    return CGSizeZero;
}
%end

%hook PINPinCloseupSponsorshipNode
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize {
    return CGSizeZero;
}
%end

%hook PINPinCloseupAbovePromotedSeparatorNode
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize {
    return CGSizeZero;
}
%end

%hook PINPinCloseupAdCloseupRPSourceNode
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize {
    return CGSizeZero;
}
%end

// ======= Layer 5: Search tab — block promoted pins in search results =======
//
// Search ads enter via two paths:
// (a) Server-side: PISearchRequestParameters.enablePromotedPins tells the API to
//     include promoted pins. Hook the getter to always return NO.
// (b) Client-side: PIContentInteractionHandler dynamically inserts ad models into
//     the search feed. Hook to no-op.
// (c) PINSearchResultsViewController re-enables promoted pins on filter changes.
//     Hook to force the promoted pins argument to NO.

%hook PISearchRequestParameters
- (BOOL)enablePromotedPins {
    return NO;
}
%end

%hook PINSearchResultsViewController
- (void)__resetToPinSearchResultsAndEnablePromotedPins:(BOOL)enable shouldReloadHeader:(BOOL)reload {
    %orig(NO, reload);
}
%end

// Block dynamic ad insertion into the search feed
%hook PIContentInteractionHandler
- (void)dynamicallyInsertModelsForModelInSearchFeed:(id)model atIndex:(NSInteger)index inContext:(id)context usingInsertionType:(NSInteger)type {
    // No-op: prevent dynamic ad insertion into search results
}
%end

// Block the API controller that fetches dynamic insertion ad payloads
%hook PIDynamicInsertionPayloadAPIController
- (id)getDynamicInsertionPayloadForModel:(id)model secondaryModel:(id)secondary inContext:(id)context fieldSet:(id)fieldSet columns:(NSInteger)columns insertionType:(NSInteger)insertionType feedType:(id)feedType feedQuery:(id)query {
    // Return nil: caller chains executeOnMainSuccess:failure: on result, messaging nil is safe
    return nil;
}
%end