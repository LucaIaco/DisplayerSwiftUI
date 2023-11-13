//
//  Displayable.ViewItem.swift
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

//MARK: - DisplayerProtocol protocol

/// Protocol which describes any object interacting with a SwiftUI view capable of
/// displaying view (navigation, modal, sheet) using the `Displayable.ViewItem`
protocol DisplayerProtocol: AnyObject, ObservableObject {
    
    /// The property which is used to display a given SwiftUI view from the view which is on screen and is
    /// associated to this displayer. This shall be implemented with the @Published property wrapper
    var displayingItem: Displayable.ViewItem { get set }
    
    /// Reference to the parent object which displayed the view associated to this displayer object
    var parentDisplayer:(any DisplayerProtocol)? { get set }
}

extension DisplayerProtocol {
    
    /// This method reset this displayer `displayingItem` view. So, any view displayed from the view associated to this displayer object should get dismissed
    func resetCurrentDisplayingItem() {
        self.displayingItem = .none
    }
    
    /// This method reset the parent coordinator `displayingItem` view. So, the view associated to this coordinator should get dismissed
    func resetParentDisplayingItem() {
        self.parentDisplayer?.displayingItem = .none
    }
    
    /// This method pushes a new view in the `displayingItem.items` array
    ///
    /// Important: In iOS 16, given the single source of truth of `NavigaitonStack`, we try to push from the
    /// `parentDisplayer`, if that exists and the `displayingItem.displayMode == .pushed`. This would be recursive
    /// - Parameter view: the view to push in the stack
    func pushView(_ view: Any) {
        if #available(iOS 16, *), let parentDisplayer, [.pushed,.none].contains( parentDisplayer.displayingItem.displayMode) {
            self.parentDisplayer?.pushView(view)
        } else {
            if self.displayingItem.displayMode == .pushed {
                self.displayingItem.pushView(view)
            }
        }
    }
    
    /// This method pop back in the navigaiton stack, in case the current `displayingItem.displayMode` is `.pushed`
    func popBack() {
        let didPop = self.displayingItem.popView()
        if !didPop, let parentDisplayer, [.pushed,.none].contains( parentDisplayer.displayingItem.displayMode) {
            parentDisplayer.popBack()
        }
    }
    
    /// This method pops to root in the navigaiton stack, in case the current `displayingItem.displayMode` is `.pushed`
    func popToRoot() {
        if #available(iOS 16, *) {
            // since iOS 16, in DisplayableModifier, we ue the single source of truth NavigationStack
            if let parentDisplayer, [.pushed,.none].contains( parentDisplayer.displayingItem.displayMode) {
                parentDisplayer.popToRoot()
            } else {
                if self.displayingItem.displayMode == .pushed {
                    self.displayingItem.popToRoot()
                }
            }
        } else {
            // until iOS 15, in DisplayableModifier, we use the NavigationView, so for each pushed view, we have a NavigationLink, and in order to pop to root, we need to pop the first NavigationLink in the sequence
            if let parentDisplayer, parentDisplayer.displayingItem.displayMode == .pushed {
                parentDisplayer.popToRoot()
            } else {
                self.displayingItem.popToRoot()
            }
        }
    }
}

/// Namespace for all the reusable displayable components
enum Displayable {}

//MARK: - Displayable.ViewItem data model

extension Displayable {
    
    /// The data model unit which describes how to display on screen the referred SwiftUI view, starting from a given SwiftUI view
    struct ViewItem:Identifiable, Equatable {
        
        /// Set of possible way for displaying a SwiftUI view
        enum DisplayMode {
            /// no displaying is expected
            case none
            /// the view will be pushed in a navigation stack
            case pushed
            /// the view will be presented fullscreen modally
            case modal
            /// the view will be presented as form sheet
            case sheet
        }
        
        //MARK: Properties
        
        let id = UUID()
        
        /// Indicates the way the `view` will be displayed
        let displayMode: ViewItem.DisplayMode
        
        /// The array of items containing the actual SwiftUI views to be displayed
        /// For modal or sheet, this will contain only one item, and so, one view
        var items: [Displayable.ViewItem.Item]
        
        /// convenience empty view
        static var none: ViewItem { ViewItem(displayMode: .none, anyView: EmptyView()) }
        
        //MARK: Initializer
        
        /// Initializes this component with the view to display and the mode to use for it
        ///
        /// the `anyView` can be any view conforming to `View` protocol or a `UIViewController`
        /// based object. In the latter, the initializer will automatically wrap the view controller
        /// in a representable SwiftUI view
        ///
        /// - Parameters:
        ///   - displayMode: The way the `view` will be displayed
        ///   - anyView: the view or representable view to be displayed
        init(displayMode:ViewItem.DisplayMode, anyView:Any) {
            self.displayMode = displayMode
            self.items = [.init(view: Self.view(from: anyView))]
        }
        
        //MARK: Private
        
        /// This method converts the provided object to a SwiftUI View object
        ///
        /// the `anyView` can be any view conforming to `View` protocol or a `UIViewController`
        /// based object. In the latter, the initializer will automatically wrap the view controller
        /// in a representable SwiftUI view
        ///
        /// - Parameter anyView: the view or representable view to be displayed
        /// - Returns: the resulting object conforming to `View`
        private static func view(from anyView:Any) -> any View {
            switch anyView {
            case let v as any View:
                return v
            case let vc as UIViewController:
                var view: any View = Displayable.UIVCWrapperView(blockMake: { _ in vc })
                // Make sure the intented navigation title set within the view controller will be actually
                // shown in the SwiftUI context
                if let navigationTitle = vc.navigationItem.title {
                    view = view.navigationTitle(navigationTitle)
                }
                return view
            default:
                return SwiftUI.Text(verbatim: "Unable to display the view. Only SwiftUI or UIViewController based views can be used")
            }
        }
        
        //MARK: Public
        
        /// If the `displayMode` is `.pushed`, this method appends a view to the stack of views
        /// - Parameter anyView: the view or representable view to be displayed
        /// - Returns: `true` if the appending was successful, `false` otherwise
        @discardableResult mutating func pushView(_ anyView:Any) -> Bool {
            guard self.displayMode == .pushed else { return false }
            self.items.append(.init(view: Self.view(from: anyView)))
            return true
        }
        
        /// If the `displayMode` is `.pushed`, this method removed the last view in the stack of views
        /// - Returns: `true` if the appending was successful, `false` otherwise
        @discardableResult mutating func popView() -> Bool {
            guard self.displayMode == .pushed else { return false }
            guard !self.items.isEmpty else { return false }
            self.items.removeLast()
            return true
        }
        
        /// If the `displayMode` is `.pushed`, this method removed all the items from the stack of views
        /// - Returns: `true` if the appending was successful, `false` otherwise
        @discardableResult mutating func popToRoot() -> Bool {
            guard self.displayMode == .pushed else { return false }
            guard !self.items.isEmpty else { return false }
            self.items.removeLast(self.items.count)
            return true
        }
                
    }
    
}

//MARK: - Displayable.ViewItem.Item data model

extension Displayable.ViewItem {
    
    /// The single Item unit wich is 1:1 to the actual SwiftUI view
    struct Item: Identifiable, Hashable {
        
        let id = UUID()
        let view: any View
        
        //MARK: Equatable & Hashable
        
        static func == (lhs:Displayable.ViewItem.Item, rhs:Displayable.ViewItem.Item) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {hasher.combine(self.id) }
    }
}
