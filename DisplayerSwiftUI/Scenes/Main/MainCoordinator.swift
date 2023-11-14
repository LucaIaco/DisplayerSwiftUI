//
//  MainCoordinator.swift
//  DisplayerSwiftUI
//
//  MIT License
//
//  Copyright (c) 2023 Luca Iaconis
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import SwiftUI

class MainCoordinator: DisplayerProtocol {
    
    //MARK: Properties
    
    @Published
    var displayingItem: Displayable.ViewItem = .none
    
    var parentDisplayer: (any DisplayerProtocol)?
    
    /// If `true`, it forces any action of pushing inside this component to be done by directly calling self.pushView() defined in the `DisplayerProtocol`
    ///
    /// See the showcase in `pushNewMainView()` for the **iOS 16+** case for more details
    let pushFromDisplayer:Bool
    
    private var window: UIWindow?
    
    //MARK: Initializer
    
    /// Initializes this coordinator
    /// - Parameters:
    ///   - parentDisplayer: Reference to the parent object which displayed the view associated to this displayer object
    ///   - pushFromDisplayer: If `true`, it forces any action of pushing inside this component to be done by directly calling self.pushView() defined in the `DisplayerProtocol`. This is needed specifically for **iOS 16+**
    init(parentDisplayer: (any DisplayerProtocol)? = nil, pushFromDisplayer: Bool = false) {
        self.parentDisplayer = parentDisplayer
        self.pushFromDisplayer = pushFromDisplayer
    }
    
    //MARK: Public
    
    /// Used in the UIKit context to initialize the MvvM-C and display it on screen
    /// - Parameter wrapInUINavigationController: if `true` it wraps the hosting controller in a navigation controller or use it as is. Default: `false`. (if `true`, pushing won't work in iOS 16 without also a NavigaitonStack)
    func start(_ wrapInUINavigationController:Bool = false) {
        
        // Create SwiftUI view
        let view = Main.buildWrappedInRoot(displayer: self,
                                           viewModel: MainViewModel(coordinator: self),
                                           navigationHandling: wrapInUINavigationController ? .handledNoWrap : .handledWrapInNavigation,
                                           title: "Home page",
                                           description: "This is the SwiftUI screen presented within a **UIHostingCongtroller**.\n\nThis view is wrapped in a **Displayable.RootView** and responds to his own **displayingItem**",
                                           closeOption: .hidden)
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        if wrapInUINavigationController {
            let hostingVC = UIHostingController(rootView: view)
            let nvc = UINavigationController(rootViewController: hostingVC)
            nvc.navigationBar.prefersLargeTitles = true
            window.rootViewController = nvc
        } else {
            window.rootViewController = UIHostingController(rootView: view)
        }
        
        window.makeKeyAndVisible()
        self.window = window
    }
    
    /// Showcases the push of a view in a navigation for the observing view
    func pushDummyView(_ uiKit:Bool) {
        let viewModel = MainViewModel(coordinator: self)
        let view: Any = uiKit ? DummyViewController(viewModel: viewModel) : DummyScreenView1(message: "Some pushed SwiftUI view", viewModel: viewModel)
        
        // Enter in navigation mode, or push the view directly on the current stack
        if !pushFromDisplayer, self.displayingItem.displayMode != .pushed {
            self.displayingItem = .init(displayMode: .pushed, anyView: view)
        } else {
            self.pushView(view)
        }
    }
    
    /// Showcases the sheet presentation of a view for the observing view
    func presentDummySheetView(_ uiKit:Bool) {
        switch uiKit {
        case true:
            self.displayingItem = .init(displayMode: .sheet, anyView: DummyViewController(viewModel: MainViewModel(coordinator: self)))
        case false:
            self.displayingItem = .init(displayMode: .sheet, anyView: DummyScreenView2(message: "Some sheet SwiftUI view", viewModel: MainViewModel(coordinator: self)))
        }
    }
    
    /// Showcases the modal/fullscreen presentation of a view for the observing view
    func presentDummyModalView(_ uiKit:Bool) {
        switch uiKit {
        case true:
            self.displayingItem = .init(displayMode: .modal, anyView: DummyViewController(viewModel: MainViewModel(coordinator: self)))
        case false:
            self.displayingItem = .init(displayMode: .modal, anyView: DummyScreenView2(message: "Some modal SwiftUI view", viewModel: MainViewModel(coordinator: self)))
        }
    }
    
    
    //Text("This is the SwiftUI screen presented from another SwiftUI view. In this case there's no UIKit involved")
    
    /// Showcases the modal/fullscreen presentation of a new instance of `MainView`
    /// Note: In this case, this would not be wrapped by a UINavigationController, so we wrap it
    /// directly here with the SwiftUI counterpart (see `wrapInNavigation` as `true`), no longer UIKit
    func presentNewMainView() {
        let newCoordinator = MainCoordinator(parentDisplayer: self)
        let view = Main.buildWrappedInRoot(displayer: newCoordinator,
                                           viewModel: MainViewModel(coordinator: newCoordinator),
                                           navigationHandling: .handledWrapInNavigation,
                                           title: "New modal MainView",
                                           description: "This is a SwiftUI view presented modally from another SwiftUI view. In this case, there's no UKit involved, and this view is wrapped within a **NavigationStack / NavigationView** in order to allow further navigation at level.\n\nThis view is wrapped in a **Displayable.RootView** and responds to to his own **MainCoordinator**, and consequently, to his own **displayingItem**",
                                           closeOption: .dismiss)
        self.displayingItem = .init(displayMode: .modal, anyView: view)
    }
    
    /// Showcases the push presentation of a new instance of `MainView`, for the **same coordinator**, and therefore, for the same navigation stack
    func pushNewMainView() {
        let view: any View
        if #available(iOS 16, *) {
//            view = Main.build(viewModel: MainViewModel(coordinator: self),
//                              title: "New pushed MainView",
//                              description: "**iOS 16+ handled**\nThis is a SwiftUI view pushed from the previous SwiftUI view **NavigationStack** (the source of truth). This view is bound to the PREVIOUS **MainCoordinator** instance, and is used as is (so, NOT wrapped in a **Displayable.RootView**).\n\n**IMPORTANT:** As you're running the app on iOS 16+ , this is then using the same **MainCoordinator** instance for the consequent pushed views (if using **displayMode = .pushed**). It means that the **displayingItem** is the same. If you try, from this view, to present modally a new view, (eg. tapping on 'Present modal view' or 'Present new modal MainView module'), it will first pop to root all the pushed views in this coordinator context, and present modally/sheet the new view.",
//                              closeOption: .popBack)
            let newCoordinator = MainCoordinator(parentDisplayer: self, pushFromDisplayer: true)
            view = Main.buildWrappedInRoot(displayer: newCoordinator,
                                           viewModel: MainViewModel(coordinator: newCoordinator),
                                           navigationHandling: .notHandled,
                                           title: "New pushed MainView",
                                           description: "**iOS 16+ handled**\nThis is a SwiftUI view pushed from the previous SwiftUI view **NavigationStack** (the source of truth).\n\nThis view is wrapped in a **Displayable.RootView** and responds to to his own **MainCoordinator**, and consequently, to his own **displayingItem**, **BUT**, the **Displayable.RootView** and the underlying **DisplayableModifier**, is configured to not handle the navigation action pop/push (**navigationHandling = .notHandled**), and the dedicated **MainCoordinator** instance is configured to push from the **parentDisplayer** (**pushFromDisplayer = true**). This allows us to navigate and independently handle modal/sheet presentation at any time in the navigation, without being first pop back to root, as the **displayingItem** for this **MainCoordinator** and the **parentDisplayer** one can work independently.",
                                           closeOption: .popBack)
            
            // Enter in navigation mode, or push the view directly on the current stack
            if !pushFromDisplayer, self.displayingItem.displayMode != .pushed {
                self.displayingItem = .init(displayMode: .pushed, anyView: view)
            } else {
                self.pushView(view)
            }
        
        } else {
            // until iOS 15, we can use only NavigaitonView and NavigationLink. Those are not designed to stack screens from one source of truth, instead they expect us to have a new NavigationLink in each new pushed view.
            let newCoordinator = MainCoordinator(parentDisplayer: self)
            view = Main.buildWrappedInRoot(displayer: newCoordinator,
                                           viewModel: MainViewModel(coordinator: newCoordinator),
                                           navigationHandling: .handledNoWrap,
                                           title: "New pushed MainView",
                                           description: "**iOS 15 handled**\nThis is a SwiftUI view pushed from the previous SwiftUI view **NavigationView**.\n\nThis view is wrapped in a **Displayable.RootView** and responds to to his own **MainCoordinator**, and consequently, to his own **displayingItem**. until iOS 15, we need to use the **NavigaitonView**, which doesn't work as source of truth like for the newly introduced iOS 16 component **NavigationStack**",
                                           closeOption: .popBack)
            // Enter in navigation mode, or push the view directly on the current stack
            if self.displayingItem.displayMode != .pushed {
                self.displayingItem = .init(displayMode: .pushed, anyView: view)
            } else {
                self.pushView(view)
            }
        }
    }
    
}
