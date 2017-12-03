# httpswitch-hap
A simple HAP (HomeKit Automation Protocol) bridge for the Kankun Smart Wifi socket in Swift

## Building

### Linux

```
sudo apt install openssl libssl-dev libsodium-dev libcurl4-openssl-dev
swift build -c release
```

### macOS

```
brew install libsodium
swift build -c release
```

To build using Xcode, use

```
brew install libsodium
swift package generate-xcodeproj
open httpswitch-hap.xcodeproj
```

## Usage
- [ ] customisable transformations between MQTT topics and HAP value updates
- [ ] access to non-default HAP Device Characteristics

