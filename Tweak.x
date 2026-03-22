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
- (BOOL)isAdsOnly;
- (BOOL)isAdsOnlyRP;
@end

@interface PINPinCloseupGalleryViewController : UIViewController
@end

@interface PINPinCloseupPinPromotionNode : NSObject
@end

@interface PINPinCloseupSponsorshipNode : NSObject
@end

@interface PINPinCloseupAbovePromotedSeparatorNode : NSObject
@end

@interface PINPinCloseupAdCloseupRPSourceNode : NSObject
@end

// Returns YES if the pin object is any kind of ad/promoted content
static BOOL isPinPromoted(id pin) {
    if (!pin) return NO;
    if ([pin respondsToSelector:@selector(isPromoted)] && [pin isPromoted]) return YES;
    if ([pin respondsToSelector:@selector(isPromotedPin)] && [pin isPromotedPin]) return YES;
    if ([pin respondsToSelector:@selector(isThirdPartyAd)] && [pin isThirdPartyAd]) return YES;
    if ([pin respondsToSelector:@selector(isSponsored)] && [pin isSponsored]) return YES;
    return NO;
}

// Returns a new array with all promoted pins removed
static NSArray *filterPromotedPins(NSArray *pins) {
    if (!pins || pins.count == 0) return pins;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:pins.count];
    for (id pin in pins) {
        if (!isPinPromoted(pin)) {
            [filtered addObject:pin];
        }
    }
    return [filtered copy];
}

// ======= Layer 1: Grid — drop promoted pin nodes entirely =======
%hook PINPinNode
- (id)initWithPin:(id)pin displayAttributes:(DisplayAttributes *)attributes {
    if ([attributes pinType] == 2) return nil;
    if (isPinPromoted(pin)) return nil;
    return %orig;
}
%end

// ======= Layer 2: Sideswipe — filter promoted pins from gallery data =======
// The closeup gallery VC has closeupPins and feedPins arrays that feed the
// sideswipe collection view. Filter promoted pins before they enter the view.
%hook PINPinCloseupGalleryViewController
- (void)setCloseupPins:(NSArray *)pins {
    %orig(filterPromotedPins(pins));
}
- (void)setFeedPins:(NSArray *)pins {
    %orig(filterPromotedPins(pins));
}
- (void)setPins:(NSArray *)pins {
    %orig(filterPromotedPins(pins));
}
%end

// ======= Layer 3: Ads-only sections and homefeed ads gate =======
// isAdsOnly/isAdsOnlyRP mark entire feed sections as ad-only carousels.
// Returning NO prevents these sections from rendering at all.
// shouldShowHomefeedAds gates whether the homefeed inserts ad pins.
%hook PIPin
- (BOOL)isAdsOnly { return NO; }
- (BOOL)isAdsOnlyRP { return NO; }
%end

// ======= Layer 4: Ad-specific closeup UI nodes =======
// These render "Promoted by X" banners, sponsorship info, and ad separators
// inside the closeup view. Returning CGSizeZero from calculateSizeThatFits:
// collapses them to invisible without breaking the Texture node tree.

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