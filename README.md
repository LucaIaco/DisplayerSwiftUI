# DisplayerSwiftUI
This project provides an alternative solution to decouple the presentation logic when dealing with SwiftUI views, in terms of modal/sheet presentation and navigation, for iOS 15 and iOS 16+.

- Used Xcode version: 15.0.1
- Tested on:
  - iOS 15.0 (iPhone and iPad)
  - iOS 17.0.1 (iPhone and iPad)

Our first goal is to be able to display a view without knowing in advance which view we aim to display, and without directly putting view or view modifiers in a given SwiftUI view (or the less possible).
Secondly, we try to reduce to the minimum the effort of handling navigation for apps running on both iOS 15 and iOS 16+. We all have to deal with the huge differences between the `NavigationView` and `NavigationLink` vs the new `NavigaitonStack`, and the this solution abstracts the concept so that you won't have to deal with them directly.
Lastly, we try to see how this works in apps which may start from a UIKit environment. 

The project contains the reusable components that make the underlying mechanism to work. You can find them under the folder `Displayable`, which are `Displayable.ViewItem.swift` and `Displayable.Views.swift`. The code is higly commented, I hope will give you a good understanding of all the showcased scenario

### Sample code to display a view

```swift
// In my DisplayerProtocol conforming object...

// displaying a SwiftUI view
self.displayingItem = .init(displayMode: .modal, anyView: DummySwiftUIView(message: "Some modal SwiftUI view", viewModel: DummyViewModel(coordinator: self)))
self.displayingItem = .init(displayMode: .sheet, anyView: DummySwiftUIView(message: "Some sheet SwiftUI view", viewModel: DummyViewModel(coordinator: self)))
self.displayingItem = .init(displayMode: .pushed, anyView: DummySwiftUIView(message: "Some pushed SwiftUI view", viewModel: DummyViewModel(coordinator: self)))
// working if this displayer or a parentDisplayer object has a `displayingItem.displayMode` as `.pushed`
self.pushView(DummySwiftUIView(message: "Some pushed SwiftUI view", viewModel: DummyViewModel(coordinator: self))) 

// displaying a UIKit view
self.displayingItem = .init(displayMode: .modal, anyView: DummyViewController(viewModel: DummyViewModel(coordinator: self)))
self.displayingItem = .init(displayMode: .sheet, anyView: DummyViewController(viewModel: DummyViewModel(coordinator: self)))
self.displayingItem = .init(displayMode: .pushed, anyView: DummyViewController(viewModel: DummyViewModel(coordinator: self)))
// working if this displayer or a parentDisplayer object has a `displayingItem.displayMode` as `.pushed`
self.pushView(DummyViewController(viewModel: DummyViewModel(coordinator: self)))
```

### Demo showcase (iOS 16 +)

https://github.com/LucaIaco/DisplayerSwiftUI/assets/7451313/e8f488f6-5ae7-4b1b-9e24-b6276ef3c898

### Demo showcase (iOS 15)

https://github.com/LucaIaco/DisplayerSwiftUI/assets/7451313/9b7153a1-7481-4e4f-a868-3c5f43598183

### DisplayerProtocol

The `DisplayerProtocol` is used by the object in charge of displaying a new view(s), from the current displayed view. It conforms already to `ObservableObject` and the exposed properties are:

```swift
/// The property which is used to display a given SwiftUI view from the view which is on screen and is
/// associated to this displayer. This shall be implemented with the @Published property wrapper
var displayingItem: Displayable.ViewItem { get set }

/// Reference to the parent object which displayed the view associated to this displayer object
var parentDisplayer:(any DisplayerProtocol)? { get set }
```

An object conforming to the `DisplayerProtocol`, will get access to the implemented methods `pushView(..)`, `popBack()`, `popToRoot()`, `resetCurrentDisplayingItem()` and `resetParentDisplayingItem()`

Assuming we are adopting an MVVM pattern architecture, this could be the view model itself or, in MVVM-Coordinator, this could be the Coordinator object implementing it (in the sample project we used a vary basic MVVM-Coordinator)

### Displayable.ViewItem

The `Displayable.ViewItem`, is the actual object that describes what view to be displayed and how, from the current displayed view. When this property changes in the conforming `DisplayerProtocol` object, the SwiftUI view will react accordingly and perform the correspoing action to display it. The view can be displayed modally, as form sheet, or pushed in the navigation. See the options in the `Displayable.ViewItem.DisplayMode`. It allows to display a SwiftUI view directly or, a UIViewController based object. In the latter, the component will automatically wrap the view controller in a `UIViewControllerRepresentable`. See the component `Displayable.UIVCWrapperView` for more info

### Displayable.RootView

This is a convenient SwiftUI view which can be used to wrap your actual content view. Behind the scene it uses the actual view modifier `Displayable.DisplayModifier`, that handles ultimately the view presentation and navigation.

```swift
/// `displayer` is the object conforming to `DisplayerProtocol` in charge of displaying view
/// `navigationHandling` indicates how the navigation (push/pop) should be handled specifically by this view
let viewToBeDisplayed = Displayable.RootView(displayer: myDisplayerObject, navigationHandling: myNavigationHandling) {
    MyContentView(viewModel: viewModel)
}
```
As you can see, this allows you to decouple the displayer from the view within the `MyContentView`, because the `Displayable.RootView` will take care of it. As alternative you can also use directly the `Displayable.DisplayModifier` if your strategy is different or you have other needs.

### Displayable.DisplayModifier
This is the core component which makes the displaying of views possible. It's a view modifier which attaches to the current view displayed on screen, and enables it to display further views from it, modally, as form sheet or pushed in navigation. If you use `Displayable.RootView` then you won't have to use this directly, as the `Displayable.RootView` will do it for you.

```swift
@Binding var displayingItem:Displayable.ViewItem
...
someContentView.displayable($displayingItem, navigationHandling: navigationHandling)
```

### Navigation - Differences between before and after iOS 16

As mentioned, SwiftUI framework provides different ways to navigate (push/pop) from a screen to another, especially very different if comparing the SDK before and after iOS 16.
Until iOS 15, we had to use `NavigationView` and `NavigationLink`, which don't provide a straightforward way to stack views unless placing `NavigationLink` in each next pushed view in the `NavigationView`. Therefore we were not able to refer to the `NavigationView` as direct source of truth. Things have changed in iOS 16, where Apple introduced the `NavigaitonStack`. It can take, as input, a path or an array of items which can be bound to the views to stack. This allows us to have one single path view list to refer as single source of truth

### Navigation - iOS 16 - NavigationStack issue with UINavigationController

Let's assume you are in a UIKit context and, more specifically, in a view controller contained in a `UINavigationController` instance, and you push a SwiftUI view wrapped in a `UIHostingController`. In iOS 16, any further push in this view won't work, unless your SwiftUI view contains a `NavigationStack`. The problem is, that putting the NavigationStack in a view which is already in a navigation (all started from `UINavigationController`) will cause a double navigation bar to happen, nested. Hiding the `NavigationStack` didn't help, at least for me. One way to explore could be to hide the navigation bar of the `UINavigationController` and see how this plays with the newly displayed one of `NavigationStack`, whether this works smoothly or causes glitches or unexpected behavior
