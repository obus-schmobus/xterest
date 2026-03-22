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

Hooks `PINPinNode` and checks `displayAttributes.pinType`. If `pinType == 2` (promoted), the pin is dropped.

## License

GPL-3.0
