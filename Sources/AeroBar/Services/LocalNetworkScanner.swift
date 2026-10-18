import Foundation
import Darwin

public class LocalNetworkScanner {
    public static let shared = LocalNetworkScanner()
    
    private init() {}
    
    /// Scan the local network for devices listening on port 8888 (or custom port)
    public func scan(
        port: UInt16 = 8888,
        progress: ((String) -> Void)? = nil,
        completion: @escaping ([String]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var candidateIps: Set<String> = []
            
            // 1. Get current local IP and subnet prefix
            let localIp = Self.getLocalIPAddress() ?? "192.168.1.100"
            let ipComponents = localIp.split(separator: ".")
            var subnetPrefix = ""
            if ipComponents.count >= 3 {
                subnetPrefix = "\(ipComponents[0]).\(ipComponents[1]).\(ipComponents[2])"
            }
            
            DispatchQueue.main.async {
                progress?("Checking ARP table on subnet \(subnetPrefix).0/24...")
            }
            
            // 2. Query ARP table for fast local device detection
            let arpIps = Self.getArpTableIPs()
            for ip in arpIps {
                if !subnetPrefix.isEmpty && ip.hasPrefix(subnetPrefix) {
                    candidateIps.insert(ip)
                } else if subnetPrefix.isEmpty {
                    candidateIps.insert(ip)
                }
            }
            
            // 3. Add entire /24 subnet to ensure we don't miss devices not yet in ARP cache
            if !subnetPrefix.isEmpty {
                for i in 1...254 {
                    candidateIps.insert("\(subnetPrefix).\(i)")
                }
            }
            
            // Prioritize ARP IPs first
            var orderedList: [String] = []
            for ip in arpIps where candidateIps.contains(ip) {
                orderedList.append(ip)
            }
            for ip in candidateIps where !orderedList.contains(ip) {
                orderedList.append(ip)
            }
            
            var discovered: [String] = []
            let lock = NSLock()
            let total = orderedList.count
            var completedCount = 0
            
            // Scan concurrently with 20 workers for Wi-Fi stability
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 20
            
            for ip in orderedList {
                queue.addOperation {
                    let isOpen = Self.checkTcpPort(ip: ip, port: port, timeoutMs: 800)
                    lock.lock()
                    completedCount += 1
                    if isOpen {
                        discovered.append(ip)
                        DispatchQueue.main.async {
                            progress?("Found AC device at \(ip):\(port)!")
                        }
                    } else if completedCount % 25 == 0 || completedCount == total {
                        let count = completedCount
                        DispatchQueue.main.async {
                            progress?("Scanning network... (\(count)/\(total))")
                        }
                    }
                    lock.unlock()
                }
            }
            
            queue.waitUntilAllOperationsAreFinished()
            
            DispatchQueue.main.async {
                progress?("Scan complete. Found \(discovered.count) device(s).")
                completion(discovered)
            }
        }
    }
    
    // MARK: - Fast BSD Socket Port Check
    
    public static func checkTcpPort(ip: String, port: UInt16, timeoutMs: Int = 350) -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }
        
        // Set non-blocking socket
        let flags = fcntl(sock, F_GETFL, 0)
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        guard inet_pton(AF_INET, ip, &addr.sin_addr) == 1 else { return false }
        
        let sockLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let res = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(sock, $0, sockLen)
            }
        }
        
        if res == 0 {
            return true
        }
        
        guard errno == EINPROGRESS else {
            return false
        }
        
        // Use poll() for timeout
        var pfd = pollfd()
        pfd.fd = sock
        pfd.events = Int16(POLLOUT)
        
        let pollRes = poll(&pfd, 1, Int32(timeoutMs))
        if pollRes > 0 && (pfd.revents & Int16(POLLOUT)) != 0 {
            var err: Int32 = 0
            var errLen = socklen_t(MemoryLayout<Int32>.size)
            getsockopt(sock, SOL_SOCKET, SO_ERROR, &err, &errLen)
            return err == 0
        }
        
        return false
    }
    
    // MARK: - Network Information
    
    public static func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // Filter en0 (standard Wi-Fi on Mac) or en1/en2
                if name.starts(with: "en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    if address != "127.0.0.1" {
                        break
                    }
                }
            }
        }
        return address
    }
    
    public static func getArpTableIPs() -> [String] {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        process.arguments = ["-a"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var ips: [String] = []
            let regex = try NSRegularExpression(pattern: "\\((([0-9]{1,3}\\.){3}[0-9]{1,3})\\)")
            let nsString = output as NSString
            let matches = regex.matches(in: output, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let ip = nsString.substring(with: match.range(at: 1))
                    ips.append(ip)
                }
            }
            return ips
        } catch {
            return []
        }
    }
}
