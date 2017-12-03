# httpswitch-hap
A simple HAP (HomeKit Automation Protocol) bridge for the Kankun Smart Wifi socket in Swift.

To make this work you need to log in install the [relay.cgi](https://drive.google.com/file/d/0B5b-Nf9ejjCKa3FtVG9MdzVQa3c/edit?usp=sharing) script on your smart plug
[as described in this post](https://www.cnx-software.com/2014/07/28/kankun-kk-sp3-wi-fi-smart-socket-hacked-based-on-atheros-ar9331-running-openwrt/).

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
```
httpswitch-hap <options>
Options:
  -d                 print debug output
  -f <version>       firmware version
  -h <host>          host device
  -k <accessorykind> light, outlet, or switch
  -m <manufacturer>  name of the manufacturer
  -n <name>          name of the HomeKit bridge
  -q                 turn off all non-critical logging output
  -s <SECRET_PIN>    HomeKit PIN for authentication
  -S <serial>        Device serial number
  -t <type>          name of the model/type
  -v                 increase logging verbosity
```
The default pin is `123-45-678`.