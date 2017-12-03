//
//  httpswitch-hap
//
//  Created by Rene Hexel on 2/12/2017.
//  Copyright © 2017 Rene Hexel. All rights reserved.
//
import Foundation
import Dispatch
import HAP

enum AccessoryKind: String {
    case light
    case outlet
    case `switch`
}

let args = CommandLine.arguments
let cmd = args[0]                   ///< command name
var name = convert(cmd, using: basename)
var verbosity = 1                   ///< verbosity level
var host = "192.168.1.191"          ///< Controller host
var pin = "123-45-678"
var vendor = "Kankun"
var type = "WiFi Plug"
var serial = "987654321"
var version = "1.0.0"
var kind = AccessoryKind.light

fileprivate func usage() -> Never {
    print("Usage: \(cmd) <options>")
    print("Options:")
    print("  -d                 print debug output")
    print("  -f <version>       firmware version [\(version)]")
    print("  -h <host>          host device [\(host)]")
    print("  -k <accessorykind> \(AccessoryKind.light.rawValue), \(AccessoryKind.outlet.rawValue), or \(AccessoryKind.switch.rawValue) [\(kind.rawValue)]")
    print("  -m <manufacturer>  name of the manufacturer [\(vendor)]")
    print("  -n <name>          name of the HomeKit bridge [\(name)]")
    print("  -q                 turn off all non-critical logging output")
    print("  -s <SECRET_PIN>    HomeKit PIN for authentication [\(pin)]")
    print("  -S <serial>        Device serial number [\(serial)]")
    print("  -t <type>          name of the model/type [\(type)]")
    print("  -v                 increase logging verbosity\n")
    exit(EXIT_FAILURE)
}

while let result = get(options: "df:h:m:n:qs:S:t:v") {
    let option = result.0
    let arg = result.1
    switch option {
    case "d": verbosity = 9
    case "f": version = arg!
    case "h": host = arg!
    case "m": vendor = arg!
    case "n": name = arg!
    case "q": verbosity  = 0
    case "s": pin = arg!
    case "S": serial = arg!
    case "t": type = arg!
    case "v": verbosity += 1
    default:
        print("Unknown option \(option)!")
        usage()
    }
}

let fm = FileManager.default
let dbPath = try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(name).path
let dbExists = fm.fileExists(atPath: dbPath)
let db: FileStorage
do {
    db = try FileStorage(path: dbPath)
} catch {
    fputs("Cannot open file storage at \(dbPath)\n", stderr)
    exit(EXIT_FAILURE)
}
if !dbExists { RunLoop.main.run(until: Date(timeIntervalSinceNow: 5)) }

let serviceInfo = Service.Info(name: name, manufacturer: vendor, model: type, serialNumber: serial, firmwareRevision: version)
let outlet: Accessory
switch kind {
case .light: outlet = Accessory.Lightbulb(info: serviceInfo)
case .outlet: outlet = Accessory.Outlet(info: serviceInfo)
case .switch: outlet = Accessory.Switch(info: serviceInfo)
}
let device = Device(bridgeInfo: serviceInfo, setupCode: pin, storage: db, accessories: [outlet])

var active = true
signal(SIGINT) { sig in
    DispatchQueue.main.async {
        active = false
        if verbosity > 0 {
            fputs("Caught signal \(sig) -- stopping!\n", stderr)
        }
    }
}

let server = try Server(device: device, port: 0)
server.start()

func update(status value: Bool?) {
    guard let set = value else { return }
    DispatchQueue.global(qos: .utility).async {
        let onOff = set ? "on" : "off"
        let urlString = "http://\(host)/cgi-bin/relay.cgi?\(onOff)"
        let url = URL(string: urlString)!
        do { _ = try Data(contentsOf: url) } catch {
            DispatchQueue.main.async { print("Cannot turn \(onOff) relay using \(urlString): \(error)") }
        }
    }
}


switch outlet {
case let light as Accessory.Lightbulb: light.lightbulb.on.onValueChange.append(update)
case let outlet as Accessory.Outlet: outlet.outlet.on.onValueChange.append(update)
case let `switch` as Accessory.Switch: `switch`.switch.on.onValueChange.append(update)
default: print("Cannot subscribe to changes for unknown accessory type '\(kind)'")
}

var checkingStatus = false
while active {
    RunLoop.current.run(until: Date().addingTimeInterval(30))
    guard !checkingStatus else { continue }
    checkingStatus = true
    DispatchQueue.global(qos: .utility).async {
        defer { DispatchQueue.main.async { checkingStatus = false } }
        let urlString = "http://\(host)/cgi-bin/relay.cgi?status"
        let url = URL(string: urlString)!
        let content: String
        do {
            let d = try Data(contentsOf: url)
            guard let s = String(data: d, encoding: .utf8), !s.isEmpty else {
                DispatchQueue.main.async { print("Cannot read from \(urlString)") }
                return
            }
            content = s
        } catch {
            DispatchQueue.main.async { print("Cannot read from \(urlString): \(error)") }
            return
        }
        let lines: [Substring]
        let ls = content.split(separator: "\r\n")
        let ms = content.split(separator: "\n")
        lines = ms.count > ls.count ? ms : ls
        guard let firstLine = lines.first else {
            DispatchQueue.main.async { print("*** Empty response from \(urlString)") }
            return
        }
        let status: Bool
        if firstLine.hasPrefix("ON") { status = true }
        else if firstLine.hasPrefix("OFF") { status = false }
        else { return }
        DispatchQueue.main.async {
            switch outlet {
            case let light as Accessory.Lightbulb: light.lightbulb.on.value = status
            case let outlet as Accessory.Outlet: outlet.outlet.on.value = status
            case let `switch` as Accessory.Switch: `switch`.switch.on.value = status
            default: return
            }
        }
    }
}

if verbosity > 2 { fputs("Stopping server.\n", stderr) }
server.stop()
if verbosity > 0 { fputs("Exiting.\n", stderr) }

RunLoop.current.run(until: Date().addingTimeInterval(1))

