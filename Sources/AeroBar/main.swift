import Cocoa

if CLIController.handleCommandLineArgs() {
    // Handled as CLI command
} else {
    // Normal GUI Menu Bar Application Launch
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}
