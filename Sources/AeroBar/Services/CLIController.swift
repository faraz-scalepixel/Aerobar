import Foundation

public class CLIController {
    public static func handleCommandLineArgs() -> Bool {
        let args = CommandLine.arguments
        
        // Filter out app executable path and macOS launchd process serial number (e.g. -psn_0_12345)
        let filteredArgs = args.dropFirst().filter { !$0.hasPrefix("-psn_") }
        guard !filteredArgs.isEmpty else {
            return false // Normal GUI launch
        }
        
        // If the first argument is "gui" or "--gui", launch GUI
        if filteredArgs.first == "gui" || filteredArgs.first == "--gui" {
            return false
        }
        
        runCLI(arguments: Array(filteredArgs))
        return true
    }
    
    private static func runCLI(arguments: [String]) {
        var ip: String? = nil
        var port: Int? = nil
        var token: String? = nil
        var useHttps: Bool? = nil
        var command: String? = nil
        var commandArg: String? = nil
        
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            if arg == "--ip" && i + 1 < arguments.count {
                ip = arguments[i + 1]
                i += 2
            } else if arg == "--port" && i + 1 < arguments.count {
                port = Int(arguments[i + 1])
                i += 2
            } else if arg == "--token" && i + 1 < arguments.count {
                token = arguments[i + 1]
                i += 2
            } else if arg == "--http" {
                useHttps = false
                i += 1
            } else if arg == "--https" {
                useHttps = true
                i += 1
            } else if arg == "-h" || arg == "--help" || arg == "help" {
                printUsage()
                exit(0)
            } else if command == nil {
                command = arg
                if i + 1 < arguments.count && !arguments[i + 1].hasPrefix("-") {
                    commandArg = arguments[i + 1]
                    i += 1
                }
                i += 1
            } else {
                i += 1
            }
        }
        
        let config = SamsungLocalConfig(ip: ip, port: port, token: token, useHttps: useHttps)
        
        switch (command ?? "status").lowercased() {
        case "status", "--status", "-s":
            print("📡 Connecting to Samsung AC at https://\(config.ip):\(config.port)/devices/0 ...")
            waitForAsync { done in
                SamsungLocalACService.shared.getStatus(config: config) { result in
                    switch result {
                    case .success(let status):
                        print("✅ Connection Successful!")
                        print("──────────────────────────────────────────")
                        print("  Power:       \(status.power ? "ON" : "OFF")")
                        if let target = status.targetTemperature {
                            print("  Target Temp: \(Int(target))°C")
                        }
                        if let room = status.roomTemperature {
                            print("  Room Temp:   \(String(format: "%.1f", room))°C")
                        }
                        if let mode = status.mode {
                            print("  Mode:        \(mode)")
                        }
                        print("──────────────────────────────────────────")
                        if let raw = status.rawResponse,
                           let jsonData = try? JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted),
                           let jsonStr = String(data: jsonData, encoding: .utf8) {
                            print("\nRaw JSON Response:\n\(jsonStr)")
                        }
                        exit(0)
                    case .failure(let err):
                        print("❌ Error fetching status: \(err.localizedDescription)")
                        exit(1)
                    }
                    done()
                }
            }
            
        case "power", "--power":
            guard let val = commandArg?.lowercased() else {
                print("❌ Missing power state. Use: power on | power off")
                exit(1)
            }
            let isOn = (val == "on" || val == "1" || val == "true")
            print("📡 Sending power \(isOn ? "ON" : "OFF") to https://\(config.ip):\(config.port)/devices/0 ...")
            waitForAsync { done in
                SamsungLocalACService.shared.setPower(isOn, config: config) { result in
                    switch result {
                    case .success(let msg):
                        print("✅ \(msg)")
                        exit(0)
                    case .failure(let err):
                        print("❌ Error: \(err.localizedDescription)")
                        exit(1)
                    }
                    done()
                }
            }
            
        case "temp", "temperature", "--temp", "--temperature":
            guard let val = commandArg, let tempC = Double(val) else {
                print("❌ Missing or invalid temperature. Example: temp 22")
                exit(1)
            }
            print("📡 Setting target temperature to \(Int(round(tempC)))°C at https://\(config.ip):\(config.port)/devices/0 ...")
            waitForAsync { done in
                SamsungLocalACService.shared.setTargetTemperature(tempC, config: config) { result in
                    switch result {
                    case .success(let msg):
                        print("✅ \(msg)")
                        exit(0)
                    case .failure(let err):
                        print("❌ Error: \(err.localizedDescription)")
                        exit(1)
                    }
                    done()
                }
            }
            
        case "mode", "--mode":
            guard let val = commandArg else {
                print("❌ Missing mode. Supported modes: Cool, Wind, Auto, Dry, Heat")
                exit(1)
            }
            print("📡 Setting operational mode to \(val) at https://\(config.ip):\(config.port)/devices/0 ...")
            waitForAsync { done in
                SamsungLocalACService.shared.setMode(val, config: config) { result in
                    switch result {
                    case .success(let msg):
                        print("✅ \(msg)")
                        exit(0)
                    case .failure(let err):
                        print("❌ Error: \(err.localizedDescription)")
                        exit(1)
                    }
                    done()
                }
            }
            
        case "scan", "--scan":
            print("🔍 Scanning local network for devices listening on port \(config.port)...")
            waitForAsync { done in
                LocalNetworkScanner.shared.scan(port: UInt16(config.port), progress: { prog in
                    print("   [\(prog)]")
                }) { discovered in
                    print("\n──────────────────────────────────────────")
                    if discovered.isEmpty {
                        print("❌ No devices found responding on port \(config.port).")
                    } else {
                        print("✅ Discovered \(discovered.count) candidate AC device(s):")
                        for devIp in discovered {
                            print("   • \(devIp):\(config.port)")
                        }
                    }
                    print("──────────────────────────────────────────")
                    exit(0)
                }
            }
            
        case "listen-token", "--listen-token", "capture-token":
            print("🎧 Starting Token Interceptor listener on 0.0.0.0:8889...")
            print("   Turn your Samsung AC off and on or trigger token request to capture the Bearer token.")
            print("   Press Ctrl+C to cancel.")
            TokenInterceptorServer.shared.start(port: 8889, onToken: { token in
                print("\n🎉 Token Captured Successfully!")
                print("──────────────────────────────────────────")
                print("TOKEN: \(token)")
                print("──────────────────────────────────────────")
                print("To use: export AC_TOKEN=\"\(token)\"")
                exit(0)
            }, onStatus: { status in
                print("   [\(status)]")
            })
            RunLoop.current.run()
            
        case "request-token", "--request-token":
            print("📡 Triggering device token request on https://\(config.ip):\(config.port)/devicetoken/request ...")
            waitForAsync { done in
                SamsungLocalACService.shared.requestDeviceToken(acIp: config.ip, acPort: config.port) { result in
                    switch result {
                    case .success(let msg):
                        print("✅ \(msg)")
                        exit(0)
                    case .failure(let err):
                        print("❌ Error: \(err.localizedDescription)")
                        exit(1)
                    }
                    done()
                }
            }
            
        default:
            print("❌ Unknown command: \(command ?? "")")
            printUsage()
            exit(1)
        }
    }
    
    private static func waitForAsync(_ block: (@escaping () -> Void) -> Void) {
        var isDone = false
        block {
            isDone = true
        }
        while !isDone {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }
    }
    
    private static func printUsage() {
        print("""
        ❄️ AeroBar Samsung Local AC CLI Controller

        USAGE:
          AeroBar <command> [argument] [options]

        COMMANDS:
          status                 Query AC status, power, room temp, target temp, and mode
          power <on|off>         Turn AC power ON or OFF
          temp <degreesC>        Set target temperature in Celsius (e.g. temp 22)
          mode <mode>            Set operational mode (Cool, Wind, Auto, Dry, Heat)
          scan                   Scan local subnet for AC devices on port 8888
          listen-token           Start background listener on port 8889 to capture token
          request-token          Send token request handshake to the AC unit
          help                   Show this help message

        OPTIONS:
          --ip <address>         AC IP Address (or env var AC_IP)
          --port <port>          AC Port (default: 8888, or env var AC_PORT)
          --token <token>        Bearer Token (or env var AC_TOKEN)

        EXAMPLES:
          AC_IP=192.168.1.100 AC_TOKEN=xyz AeroBar status
          AeroBar --ip 192.168.1.100 --token xyz power on
          AeroBar --ip 192.168.1.100 --token xyz temp 22
          AeroBar scan
          AeroBar listen-token
        """)
    }
}
