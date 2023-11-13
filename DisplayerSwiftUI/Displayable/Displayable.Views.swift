//
//  Displayable.Views.swift
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
import SwiftUI

//MARK: - Displayable.UIVCWrapperView component

extension Displayable {
    
    /// Base generic View representable which allows to display a `UIViewController` based object
    struct UIVCWrapperView<T:UIViewController>: UIViewControllerRepresentable {
        
        typealias VCType = T
        
        /// Initializes the view controller wrapper view
        /// - Parameters:
        ///   - blockMake: the closure which injects the actual View controller to display
        ///   - blockUpdate: the closure which is called in the `updateUIViewController(:)` method
        init(blockMake: @escaping (_: Context) -> VCType, blockUpdate: ((_: VCType, _: Context) -> ())? = nil) {
            self.blockMake = blockMake
            self.blockUpdate = blockUpdate
        }
        
        let blockMake: (_ context:Context) -> VCType
        let blockUpdate: ((_ uiViewController:VCType, _ context:Context) -> ())?
        
        func makeUIViewController(context: Context) -> VCType { blockMake(context) }
        func updateUIViewController(_ vc: VCType, context: Context) { blockUpdate?(vc, context) }
    }
}

//MARK: - Displayable.RootView component

extension Displayable {
    
    /// View which, as alternative to the `DisplayModifier`, displays views based on a `Displayable.ViewItem`
    struct RootView<Displayer:DisplayerProtocol, Content: View>: View {
        
        //MARK: Properties
        
        /// Observed object conforming to the `DisplayerProtocol`
        @ObservedObject private var displayer: Displayer
        
        /// The type of navigation handling to adopt for this modifier
        private let navigationHandling:Displayable.NavigationHandling
        
        /// The actual content which will be displayed within this view
        private let content: () -> Content
        
        /// Property that bridges the read/write of `displayingItem` exposed in `coordinator`
        @Binding private var displayingItem:Displayable.ViewItem
        
        //MARK: Initializer
        
        /// Initializes the `Displayable.RootView` component
        /// - Parameters:
        ///   - displayer: the observable object conforming to `DisplayerProtocol`
        ///   - navigationHandling: the type of navigation handling to adopt for this modifier. Default is `handledNoWrap`
        ///   - content: the actual content to be displayed on screen
        init(displayer: Displayer, navigationHandling:Displayable.NavigationHandling = .handledNoWrap, @ViewBuilder content: @escaping () -> Content) {
            self.displayer = displayer
            self._displayingItem = Binding(get: {
                displayer.displayingItem
            }, set: {
                displayer.displayingItem = $0
            })
            self.navigationHandling = navigationHandling
            self.content = content
        }
        
        //MARK: View
        
        var body: some View {
            content().displayable($displayingItem, navigationHandling: navigationHandling)
        }
        
    }
}

//MARK: - Displayable.DisplayModifier

fileprivate extension Displayable {
    
    /// View modifier capable of handling the displaying of views
    struct DisplayModifier: ViewModifier {
        
        //MARK: Properties
        
        @Binding var displayingItem:Displayable.ViewItem
        
        /// The type of navigation handling to adopt for this modifier
        let navigationHandling:Displayable.NavigationHandling
        
        @State private var isActiveSheet = false
        @State private var isActiveModal = false
        
        /// For iOS 16+ : Binding proxy to the `displayingItem.items`, used directly by the `NavigationStack`
        @Binding private var navigationItems:[Displayable.ViewItem.Item]
        /// For iOS 15 : Exposes the last pushed item identifier, used directly by the `NavigationLink`
        @Binding private var curNavItem: Displayable.ViewItem.Item?
        private var lastNavItem: Displayable.ViewItem.Item { navigationItems.last ?? .init(view: EmptyView()) }
        
        //MARK: Initializer
        
        init(displayingItem: Binding<Displayable.ViewItem>, navigationHandling:Displayable.NavigationHandling) {
            self._displayingItem = displayingItem
            // Needed for iOS 16+, here we're bridging the binding to the outer binding of displayingItem.
            // This is necessary, to let the NavigationStack to update the displayingItem.items outside
            self._navigationItems = Binding(get: {
                // makes sure that if we are not pushing, the NavigationStack will reset his state or do nothing
                displayingItem.wrappedValue.displayMode == .pushed ? displayingItem.wrappedValue.items : []
            }, set: {
                // makes sure that the outer displayingItem will be updated only if displayMode is 'pushed'.
                // This setter is called when the user manually pops back (horizontal swipe or back button in
                // the navigaiton bar)
                guard displayingItem.wrappedValue.displayMode == .pushed else { return }
                displayingItem.wrappedValue.items = $0
            })
            // Needed for iOS 15, here we're getting the current item to be pushed from the displayingItem.items
            self._curNavItem = Binding(get: {
                guard displayingItem.wrappedValue.displayMode == .pushed else { return nil }
                return displayingItem.wrappedValue.items.last
            }, set: { newItem in
                // makes sure that the outer displayingItem will be updated only if displayMode is 'pushed'
                guard displayingItem.wrappedValue.displayMode == .pushed,
                      newItem == nil, !displayingItem.wrappedValue.items.isEmpty else { return }
                // This setter is called when the user manually pops back (horizontal swipe or back button in
                // the navigaiton bar)
                displayingItem.wrappedValue.items.removeLast()
            })
            self.navigationHandling = navigationHandling
            self.isActiveSheet = false
            self.isActiveModal = false
        }
        
        //MARK: Body
        
        func body(content: Content) -> some View {
            Group {
                switch navigationHandling {
                case .handledWrapInNavigation:
                    if #available(iOS 16, *) {
                        NavigationStack(path: $navigationItems) {
                            content.navigationDestination(for: Displayable.ViewItem.Item.self) { item in
                                AnyView(item.view)
                            }
                        }
                    } else {
                        NavigationView {
                            // NavigationView looks for the first concrete child, so we wrap all in there
                            VStack(spacing:0) {
                                content
                                NavigationLink(destination: AnyView(lastNavItem.view), tag: lastNavItem, selection: $curNavItem, label: { EmptyView() })
                                    .isDetailLink(false)
                            }
                        }.navigationViewStyle(.stack)
                    }
                case .handledNoWrap:
                    if #available(iOS 16, *) {
                        // IMPORTANT: navigationDestination doesn't work without NavigationStack.
                        // If the view is within an UINavigationController in UIKit, the push won't happen with
                        // the view modifier navigationDestination, and adding NavigationStack would cause
                        // nested navigation as undesired behavior
                        content.navigationDestination(for: Displayable.ViewItem.Item.self) { item in
                            AnyView(item.view)
                        }
                    } else {
                        content
                        NavigationLink(destination: AnyView(lastNavItem.view), tag: lastNavItem, selection: $curNavItem, label: { EmptyView() })
                            .isDetailLink(false)
                    }
                case .notHandled:
                    content
                }
            }.sheet(isPresented: $isActiveSheet, onDismiss: {
                // reset the displaying item back to `none` once the modal got dismissed
                self.displayingItem = .none
            }) {
                AnyView(displayingItem.items[0].view)
            }.fullScreenCover(isPresented: $isActiveModal, onDismiss: {
                // reset the displaying item back to `none` once the modal got dismissed
                self.displayingItem = .none
            }) {
                AnyView(displayingItem.items[0].view)
            }
            .onChange(of: displayingItem) { newVal in
                isActiveSheet = (newVal.displayMode == .sheet)
                isActiveModal = (newVal.displayMode == .modal)
            }
        }
        
    }
}

extension Displayable {
    
    /// Set of options which can be used in the `DisplayModifier` for handling the navigation stack
    enum NavigationHandling {
        /// It handles the navigation, and wraps the content in a NavigaitonStack / NavigationView
        ///
        /// The content gets wrapped in a NavigationStack (iOS 16+) or NavigaitonView (iOS 15), and makes explicit use of .navigationDestination (iOS 16+) or NavigationLink (iOS 15)
        case handledWrapInNavigation
        /// It handles the navigation, using the content as is, and makes explicit use of .navigationDestination (iOS 16+) or NavigationLink (iOS 15)
        case handledNoWrap
        /// It does not handle the navigation. It means, if the `displayingItem` passed to `DisplayModifier` has `displayMode` set as `pushed`, no action will be taken, Therefore only `.modal` and `.sheet` will work.
        ///
        /// Worth to mention, this will not place in the view any view or view modifier which serves the purpose of navigating (so, no NavigaitonStack / NavigationView / NavigationLink, navigationDestination() )
        case notHandled
    }
    
}

//MARK: - Helper View extension

extension View {
    
    /// Helper modifier which attaches the `DisplayModifier` to this view
    /// - Parameter displayingItem: the displayable item to observe
    /// - Parameter navigationHandling: The type of navigation handling to adopt for this modifier
    func displayable(_ displayingItem:Binding<Displayable.ViewItem>, navigationHandling:Displayable.NavigationHandling) -> some View {
        modifier(Displayable.DisplayModifier(displayingItem: displayingItem, navigationHandling:navigationHandling))
    }
}

