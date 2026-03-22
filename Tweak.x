#import <UIKit/UIKit.h>

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
@end

// Block promoted pins from the homefeed grid
%hook PINPinNode
- (id)initWithPin:(id)pin displayAttributes:(DisplayAttributes *)attributes {
    if ([attributes pinType] == 2) {
        return nil;
    }
    return %orig(pin, attributes);
}
%end

// Override ad booleans on the pin data model.
// Catches ads in closeup sideswipe, related pins, stories, and anywhere
// else that checks these properties instead of pinType.
%hook PIPin
- (BOOL)isPromoted { return NO; }
- (BOOL)isPromotedPin { return NO; }
- (BOOL)isThirdPartyAd { return NO; }
- (BOOL)isSponsored { return NO; }
%end