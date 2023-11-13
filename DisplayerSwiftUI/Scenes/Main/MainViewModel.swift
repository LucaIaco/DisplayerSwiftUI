//
//  MainViewModel.swift
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

/// The view model
class MainViewModel: ObservableObject {
    
    //MARK: Properties
    
    private let coordinator:MainCoordinator
    
    @Published
    var viewType:MainViewModel.ViewType = .swiftUI
    
    //MARK: Initializer
    
    init(coordinator:MainCoordinator) {
        self.coordinator = coordinator
    }
    
    //MARK: Public
    
    /// Launches the given showcase
    /// - Parameter option: the showcase option to launch
    func showcase(_ option:MainViewModel.Showcase) {
        switch option {
        case .pushDummyView: coordinator.pushDummyView(viewType == .uiKit)
        case .presentDummySheet: coordinator.presentDummySheetView(viewType == .uiKit)
        case .presentDummyModal: coordinator.presentDummyModalView(viewType == .uiKit)
        case .presentNewMainView: coordinator.presentNewMainView()
        case .pushNewMainView: coordinator.pushNewMainView()
        case .resetCurrentDisplayingItem: coordinator.resetCurrentDisplayingItem()
        case .resetParentDisplayingItem: coordinator.resetParentDisplayingItem()
        case .popBack: coordinator.popBack()
        case .popToRoot: coordinator.popToRoot()
        }
    }
}

extension MainViewModel {
    enum Showcase {
        case pushDummyView
        case presentDummySheet
        case presentDummyModal
        case presentNewMainView
        case pushNewMainView
        case resetCurrentDisplayingItem
        case resetParentDisplayingItem
        case popBack
        case popToRoot
    }
}

extension MainViewModel {
    enum ViewType:Int {
        case swiftUI = 0
        case uiKit = 1
    }
}
