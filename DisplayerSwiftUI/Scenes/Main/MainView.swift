//
//  MainView.swift
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

enum Main {
    
    /// Builds and returns the `Main.ContentView` to be displayed, wrapped in a `Displayable.RootView`
    ///
    /// This method binds the object conforming to `DisplayerProtocol` and plugs it in the generic view component `Displayable.RootView`, in order to not expose it directly to the actual content view (in this case, `Main.ContentView`).
    ///
    /// The view model gets attached to the actual content view. Despite inside it refers to the coordinator, this is not exposed to the view. The content view (`Main.ContentView`) will communicate only with the view model for any need
    ///
    /// - Parameters:
    ///   - displayer: the object conforming to `DisplayerProtocol`
    ///   - viewModel: the specific view model for the `Main.ContentView`
    ///   - navigationHandling: indicates the type of handling adopted by the `Displayable.RootView`. Default is `handledNoWrap`
    ///   - title: the `Main.ContentView` title in case is displayed in a navigation stack
    ///   - description: the `Main.ContentView` description
    ///   - closeOption: they option to take for the visibility and type of close button in the showcase view
    /// - Returns: the `Displayable.RootView` wrapping the `Main.ContentView`
    @ViewBuilder static func buildWrappedInRoot<Displayer:DisplayerProtocol>(displayer:Displayer, viewModel: MainViewModel, navigationHandling:Displayable.NavigationHandling = .handledNoWrap, title: String, description: LocalizedStringKey, closeOption: Main.ContentView.CloseButtonOption) -> some View {
        Displayable.RootView(displayer: displayer, navigationHandling: navigationHandling) {
            Self.build(viewModel: viewModel,
                       title: title, 
                       description: description,
                       closeOption: closeOption)
        }
    }
    
    /// Builds and returns the `Main.ContentView` to be displayed
    /// - Parameters:
    ///   - viewModel: the specific view model for the `Main.ContentView`
    ///   - title: the `Main.ContentView` title in case is displayed in a navigation stack
    ///   - description: the `Main.ContentView` description
    ///   - closeOption: the option to take for the visibility and type of close button in the showcase view
    /// - Returns: the `Main.ContentView`
    @ViewBuilder static func build(viewModel: MainViewModel, title: String, description: LocalizedStringKey, closeOption:Main.ContentView.CloseButtonOption) -> some View {
        Main.ContentView(viewModel: viewModel,
                         title: title,
                         description: description,
                         closeOption: closeOption)
    }
    
    /// Just the showcase view for the POC
    struct ContentView: View {
        
        @StateObject var viewModel:MainViewModel
        
        let title:String
        let description:LocalizedStringKey
        
        let closeOption:Main.ContentView.CloseButtonOption
        
        enum CloseButtonOption {
            case hidden
            case dismiss
            case popBack
        }
        
        var body: some View {
            List {
                // Description section
                Section("Description") {
                    Text(description)
                }
                
                // Close button section
                switch closeOption {
                case .hidden:
                    EmptyView()
                case .dismiss:
                    Section {
                        Button("Dismiss this view", role: .destructive) { viewModel.showcase(.resetParentDisplayingItem) }
                    }
                case .popBack:
                    Section {
                        Button("Pop back", role: .destructive) { viewModel.showcase(.popBack) }
                        Button("Pop to root", role: .destructive) { viewModel.showcase(.popToRoot) }
                    }
                }
                
                // Showcase sections to display views
                
                Section("Push new module (Same Coordinator, Same RootView, New View model)") {
                    Button("Push new MainView") { viewModel.showcase(.pushNewMainView) }
                }
                
                Section("Present new module (New Coordinator, New RootView, New View model)") {
                    Button("Present new modal MainView module") { viewModel.showcase(.presentNewMainView) }
                }
                
                Section("Display dummy views only") {
                    Picker("", selection: $viewModel.viewType) {
                        Text("SwiftUI").tag(MainViewModel.ViewType.swiftUI)
                        Text("UIViewController").tag(MainViewModel.ViewType.uiKit)
                    }.pickerStyle(.segmented)
                    
                    Button("Push view") { viewModel.showcase(.pushDummyView) }
                    Button("Present sheet view") { viewModel.showcase(.presentDummySheet) }
                    Button("Present modal view") { viewModel.showcase(.presentDummyModal) }
                }
                
            }.navigationTitle(title)
        }
    }
}
