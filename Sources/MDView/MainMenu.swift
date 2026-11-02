import AppKit

enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()
        let name = ProcessInfo.processInfo.processName

        main.addSubmenu("") {
            $0.addItem("About \(name)", #selector(NSApplication.orderFrontStandardAboutPanel(_:)))
            $0.addItem(.separator())
            let services = NSMenu()
            $0.addItem("Services", nil).submenu = services
            NSApp.servicesMenu = services
            $0.addItem(.separator())
            $0.addItem("Hide \(name)", #selector(NSApplication.hide(_:)), "h")
            $0.addItem("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option])
            $0.addItem("Show All", #selector(NSApplication.unhideAllApplications(_:)))
            $0.addItem(.separator())
            $0.addItem("Quit \(name)", #selector(NSApplication.terminate(_:)), "q")
        }

        main.addSubmenu("File") {
            $0.addItem("Open…", #selector(NSDocumentController.openDocument(_:)), "o")
            let recent = NSMenu(title: "Open Recent")
            recent.addItem("Clear Menu", #selector(NSDocumentController.clearRecentDocuments(_:)))
            // Lets NSDocumentController find and populate this menu.
            recent.perform(NSSelectorFromString("_setMenuName:"), with: "NSRecentDocumentsMenu")
            $0.addItem("Open Recent", nil).submenu = recent
            $0.addItem(.separator())
            $0.addItem("Close", #selector(NSWindow.performClose(_:)), "w")
            $0.addItem("Reveal in Finder", #selector(ViewerWindowController.revealInFinder(_:)), "r", [.command, .shift])
            $0.addItem(.separator())
            $0.addItem("Print…", #selector(NSDocument.printDocument(_:)), "p")
        }

        main.addSubmenu("Edit") {
            $0.addItem("Copy", #selector(NSText.copy(_:)), "c")
            $0.addItem("Select All", #selector(NSText.selectAll(_:)), "a")
            $0.addItem(.separator())
            $0.addItem("Find…", #selector(ViewerWindowController.showFind(_:)), "f")
            $0.addItem("Find Next", #selector(ViewerWindowController.findNextMatch(_:)), "g")
            $0.addItem("Find Previous", #selector(ViewerWindowController.findPreviousMatch(_:)), "g", [.command, .shift])
            $0.addItem("Filter Files…", #selector(FolderViewController.filterFiles(_:)), "o", [.command, .shift])
        }

        main.addSubmenu("View") {
            $0.addItem("Reload", #selector(ViewerWindowController.reloadDocument(_:)), "r")
            $0.addItem(.separator())
            $0.addItem("Back", #selector(FolderViewController.goBack(_:)), "[")
            $0.addItem("Forward", #selector(FolderViewController.goForward(_:)), "]")
            $0.addItem("Toggle Sidebar", #selector(NSSplitViewController.toggleSidebar(_:)), "s", [.command, .control])
            $0.addItem(.separator())
            $0.addItem("Actual Size", #selector(ViewerWindowController.actualSize(_:)), "0")
            $0.addItem("Zoom In", #selector(ViewerWindowController.zoomInText(_:)), "+")
            $0.addItem("Zoom Out", #selector(ViewerWindowController.zoomOutText(_:)), "-")
            $0.addItem(.separator())
            $0.addItem("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control])
        }

        let window = main.addSubmenu("Window") {
            $0.addItem("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m")
            $0.addItem("Zoom", #selector(NSWindow.performZoom(_:)))
            $0.addItem(.separator())
            $0.addItem("Bring All to Front", #selector(NSApplication.arrangeInFront(_:)))
        }
        NSApp.windowsMenu = window

        return main
    }
}

private extension NSMenu {
    @discardableResult
    func addSubmenu(_ title: String, _ build: (NSMenu) -> Void) -> NSMenu {
        let menu = NSMenu(title: title)
        build(menu)
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        addItem(item)
        return menu
    }

    @discardableResult
    func addItem(_ title: String, _ action: Selector?, _ key: String = "",
                 _ modifiers: NSEvent.ModifierFlags = .command) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        addItem(item)
        return item
    }
}
