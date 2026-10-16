import Cocoa
import SwiftUI
import Combine

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from quitting when windows close
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        observeState()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateStatusItemTitle()
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 330, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(rootView: MenuBarView(state: ACState.shared))
    }
    
    private func observeState() {
        ACState.shared.$targetTemperature
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
            
        ACState.shared.$isOn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItemTitle() {
        guard let button = statusItem.button else { return }
        
        let state = ACState.shared
        let tempText = state.isOn ? "\(state.formattedTargetTemp)°" : "OFF"
        
        // Custom synthesized status bar icon
        let icon = createStatusIcon(isOn: state.isOn)
        button.image = icon
        button.imagePosition = .imageLeading
        button.title = " \(tempText)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Re-anchor and present
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    // Creates a crisp AC icon for the menu bar
    private func createStatusIcon(isOn: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 14)
        let image = NSImage(size: size, flipped: false) { rect in
            let strokeColor = NSColor.labelColor.withAlphaComponent(isOn ? 1.0 : 0.45)
            strokeColor.setStroke()
            
            // AC main body outline
            let bodyRect = NSRect(x: 1, y: 5, width: 16, height: 8)
            let path = NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2)
            path.lineWidth = 1.2
            path.stroke()
            
            // Vent line
            let ventPath = NSBezierPath()
            ventPath.move(to: NSPoint(x: 3, y: 7))
            ventPath.line(to: NSPoint(x: 15, y: 7))
            ventPath.lineWidth = 0.8
            ventPath.stroke()
            
            // Breeze indicators below
            if isOn {
                let waveColor = NSColor.labelColor.withAlphaComponent(0.75)
                waveColor.setStroke()
                
                let bPath = NSBezierPath()
                bPath.move(to: NSPoint(x: 4, y: 4))
                bPath.line(to: NSPoint(x: 6, y: 1))
                
                bPath.move(to: NSPoint(x: 9, y: 4))
                bPath.line(to: NSPoint(x: 10, y: 1))
                
                bPath.move(to: NSPoint(x: 14, y: 4))
                bPath.line(to: NSPoint(x: 13, y: 1))
                
                bPath.lineWidth = 1.0
                bPath.stroke()
            }
            
            return true
        }
        image.isTemplate = true
        return image
    }
}
