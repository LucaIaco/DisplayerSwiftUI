//
//  DummyViews.swift
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

import UIKit
import SwiftUI

/// Dummy view 1 (used for showcase(.pushDummyView))
struct DummyScreenView1: View {
    let message:String
    @StateObject var viewModel:MainViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
            Button("Pop back", role: .destructive) { viewModel.showcase(.popBack) }
            Button("Pop to root", role: .destructive) { viewModel.showcase(.popToRoot) }
        }.navigationTitle("My dummy title")
    }
}

/// Dummy view 2 (used for showcase(.presentDummySheet) and showcase(.presentDummyModal))
struct DummyScreenView2: View {
    let message:String
    @StateObject var viewModel:MainViewModel
    
    var body: some View {
        VStack(spacing:20) {
            Text(message)
            Button("Dismiss", role: .destructive) { viewModel.showcase(.resetCurrentDisplayingItem) }
        }
    }
}

class DummyViewController: UIViewController {
    
    //MARK: Properties
    
    var viewModel:MainViewModel?
    
    private var didSetup = false
    
    //MARK: Initializers
    
    init(viewModel: MainViewModel? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        // This, as is within a UIViewControllerRepresentable wouldn't work, so in `Dislayable.ViewItem` will
        // take care of setting this title as view modifier .navigationTitle("My title") without glitches
        self.navigationItem.title = "My UIKit Title"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK: View lifecycle
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // A view controller presented in a UIViewControllerRepresentable from a SwiftUI view
        // seems to be bridged first in a SwiftUI private uiviewcontroller subclass.
        // Since it seems we cannot simply set `self.navigationItem.title`, we need to perform
        // this `trick` to make it working.
        //
        // For reference, pseudo private parents view controllers:
        // SwiftUI_NavigationStackHostingController_AnyView_ (when pushed in a navigation)
        // SwiftUI_PresentationHostingController_AnyView_ (when presented modally)
        //self.parent?.navigationItem.title = "My title"
        
        // The cleanest way so far, is to set the title from outside, with the SwiftUI view modifier
        // .navigationTitle("My title")
    }
    
    //MARK: Private
    
    private func setup() {
        guard !self.didSetup else { return }
        self.didSetup = true
        
        let rootStack = UIStackView()
        rootStack.axis = .vertical
        rootStack.spacing = 20
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(rootStack)
        rootStack.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        rootStack.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        rootStack.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        let lblTitle = UILabel()
        lblTitle.numberOfLines = 0
        lblTitle.textAlignment = .center
        lblTitle.text = "UIViewController\ndisplayed from SwiftUI context"
        rootStack.addArrangedSubview(lblTitle)
        
        // If not pushed, show a close button, otherwise the pop back/to root
        if (self.navigationController?.viewControllers.count ?? 0 <= 1 ) {
            
            let btnClose = UIButton(primaryAction: UIAction(title:"Dismiss", handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }))
            btnClose.tintColor = .red
            rootStack.addArrangedSubview(btnClose)
            
            let btnCloseViaCoordinator = UIButton(primaryAction: UIAction(title:"Dismiss from Coordinator", handler: { [weak self] _ in
                self?.viewModel?.showcase(.resetCurrentDisplayingItem)
            }))
            btnCloseViaCoordinator.tintColor = .red
            rootStack.addArrangedSubview(btnCloseViaCoordinator)
            
        } else {
            
            let btnPopBack = UIButton(primaryAction: UIAction(title:"Pop back", handler: { [weak self] _ in
                self?.viewModel?.showcase(.popBack)
            }))
            btnPopBack.tintColor = .red
            rootStack.addArrangedSubview(btnPopBack)
            
            let btnPopToRoot = UIButton(primaryAction: UIAction(title:"Pop to root", handler: { [weak self] _ in
                self?.viewModel?.showcase(.popToRoot)
            }))
            btnPopToRoot.tintColor = .red
            rootStack.addArrangedSubview(btnPopToRoot)
            
        }
    }
    
}
