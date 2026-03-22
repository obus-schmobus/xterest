# xterest

Pinterest ad blocker tweak. Blocks sponsored/promoted pins.

Fork of [authorisation/xterest](https://github.com/authorisation/xterest).

## Download

Grab the latest build (no GitHub login required):

**[⬇ xterest-build.zip](https://nightly.link/obus-schmobus/xterest/workflows/build/main/xterest-build.zip)**

Contains:
- `.deb` packages (debug + release, rootful + rootless)
- `xterest.dylib` — standalone dylib for LiveContainer / sideloading

## Build

Requires [Theos](https://theos.dev).

```sh
# debug
make package

# release
make package FINALPACKAGE=1

# rootless
make package THEOS_PACKAGE_SCHEME=rootless
```

## How it works

Multi-layered ad removal:

1. **Grid** — Hooks `PINPinNode initWithPin:displayAttributes:`. Drops nodes with `pinType == 2` (promoted) or where the pin model reports promoted/sponsored.
2. **Sideswipe** — Blocks third-party ad sideswipes (`PIThirdParty.sideswipePin → nil`) and forces `promotedIsSideswipeDisabled → YES` on all `PIPin` objects to prevent promoted sideswipe content.
3. **Ads-only sections** — Forces `isAdsOnly` and `isAdsOnlyRP` to `NO` on `PIPin`, preventing entire ad-only carousels from rendering.
4. **Closeup UI cleanup** — Collapses ad-specific Texture nodes (`PINPinCloseupPinPromotionNode`, `PINPinCloseupSponsorshipNode`, etc.) to zero size so no "Promoted by" or sponsorship UI leaks through.
5. **Search** — Disables promoted pins in search requests (`PISearchRequestParameters.enablePromotedPins → NO`), blocks dynamic ad insertion into search feeds, and prevents re-enabling promoted pins on filter changes.

## License

GPL-3.0
