import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.removeDefaultMenus()
        }
    }
    
    private func removeDefaultMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }
        
        let menusToRemove = ["File", "Edit", "View", "Go", "Window", "Help"]
        
        for title in menusToRemove {
            if let index = mainMenu.items.firstIndex(where: { $0.title == title }) {
                mainMenu.removeItem(at: index)
            }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}
