SwinjectStoryboard
========

[![Build Status](https://travis-ci.org/Swinject/SwinjectStoryboard.svg?branch=master)](https://travis-ci.org/Swinject/SwinjectStoryboard)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/SwinjectStoryboard.svg?style=flat)](http://cocoapods.org/pods/SwinjectStoryboard)
[![License](https://img.shields.io/cocoapods/l/SwinjectStoryboard.svg?style=flat)](http://cocoapods.org/pods/SwinjectStoryboard)
[![Platform](https://img.shields.io/cocoapods/p/SwinjectStoryboard.svg?style=flat)](http://cocoapods.org/pods/SwinjectStoryboard)
[![Swift Version](https://img.shields.io/badge/Swift-3-F16D39.svg?style=flat)](https://developer.apple.com/swift)

SwinjectStoryboard is an extension of Swinject to automatically inject dependency to view controllers instantiated by a storyboard.

## Requirements

- iOS 8.0+ / Mac OS X 10.10+ / tvOS 9.0+
- Xcode 8+

## Installation

Swinject is available through [Carthage](https://github.com/Carthage/Carthage) or [CocoaPods](https://cocoapods.org).

### Carthage

To install Swinject with Carthage, add the following line to your `Cartfile`.

```
github "Swinject/Swinject"
github "Swinject/SwinjectStoryboard"
```

Then run `carthage update --no-use-binaries` command or just `carthage update`. For details of the installation and usage of Carthage, visit [its project page](https://github.com/Carthage/Carthage).

### CocoaPods

To install Swinject with CocoaPods, add the following lines to your `Podfile`.

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0' # or platform :osx, '10.10' if your target is OS X.
use_frameworks!

pod 'Swinject'
pod 'SwinjectStoryboard'
```

Then run `pod install` command. For details of the installation and usage of CocoaPods, visit [its official website](https://cocoapods.org).

## Usage

Swinject supports automatic dependency injection to view controllers instantiated by `SwinjectStoryboard`. This class inherits `UIStoryboard` (or `NSStoryboard` in case of OS X). To register dependencies of a view controller, use `storyboardInitCompleted` method. In the same way as a registration of a service type, a view controller can be registered with or without a name.

**NOTE**: Do NOT explicitly resolve the view controllers registered by `storyboardInitCompleted` method. The view controllers are intended to be resolved by `SwinjectStoryboard` implicitly.

### Registration

#### Registration without Name

Here is a simple example to register a dependency of a view controller without a registration name:

```swift
let container = Container()
container.storyboardInitCompleted(AnimalViewController.self) { r, c in
    c.animal = r.resolve(Animal.self)
}
container.register(Animal.self) { _ in Cat(name: "Mimi") }
```

Next, we create an instance of `SwinjectStoryboard` with the container specified. If the container is not specified, `SwinjectStoryboard.defaultContainer` is used instead. `instantiateViewControllerWithIdentifier` method creates an instance of the view controller with its dependencies injected:

```swift
let sb = SwinjectStoryboard.create(
    name: "Animals", bundle: nil, container: container)
let controller = sb.instantiateViewControllerWithIdentifier("Animal")
    as! AnimalViewController
print(controller.animal! is Cat) // prints "true"
print(controller.animal!.name) // prints "Mimi"
```

Where the classes and protocol are:

```swift
class AnimalViewController: UIViewController {
    var animal: Animal?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol Animal {
    var name: String { get set }
}

class Cat: Animal {
    var name: String

    init(name: String) {
        self.name = name
    }
}
```

and the storyboard named `Animals.storyboard` has `AnimalViewController` with storyboard ID `Animal`.

![AnimalViewController in Animals.storyboard](./Assets/AnimalViewControllerScreenshot1.png)

#### Registration with Name

If a storyboard has more than one view controller with the same type, dependencies should be registered with registration names.

```swift
let container = Container()
container.storyboardInitCompleted(AnimalViewController.self, name: "cat") {
    r, c in c.animal = r.resolve(Animal.self, name: "mimi")
}
container.storyboardInitCompleted(AnimalViewController.self, name: "dog") {
    r, c in c.animal = r.resolve(Animal.self, name: "hachi")
}
container.register(Animal.self, name: "mimi") {
    _ in Cat(name: "Mimi")
}
container.register(Animal.self, name: "hachi") {
    _ in Dog(name: "Hachi")
}
```

Then view controllers are instantiated with storyboard IDs similarly to the case without registration names:

```swift
let sb = SwinjectStoryboard.create(
    name: "Animals", bundle: nil, container: container)
let catController = sb.instantiateViewControllerWithIdentifier("Cat")
    as! AnimalViewController
let dogController = sb.instantiateViewControllerWithIdentifier("Dog")
    as! AnimalViewController
print(catController.animal!.name) // prints "Mimi"
print(dogController.animal!.name) // prints "Hachi"
```

Where `Dog` class is:

```swift
class Dog: Animal {
    var name: String

    init(name: String) {
        self.name = name
    }
}
```

and the storyboard named `Animals.storyboard` has `AnimalViewController`s with storyboard IDs `Cat` and `Dog`. In addition to the storyboard IDs, user defined runtime attributes are specified as `cat` and `dog` for the key `swinjectRegistrationName`, respectively.

![AnimalViewControllers with user defined runtime attribute in Animals.storyboard](./Assets/AnimalViewControllerScreenshot2.png)

### UIWindow and Root View Controller Instantiation

#### Implicit Instantiation from "Main" Storyboard

If you implicitly instantiate `UIWindow` and its root view controller from "Main" storyboard, implement `setup` class method as an extension of `SwinjectStoryboard` to register dependencies to `defaultContainer`. When the root view controller (initial view controller) is instantiated by runtime, dependencies registered to `defaultContainer` are injected.

**Note that `@objc` attribute is mandatory here in swift 4.**

```swift
extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.storyboardInitCompleted(AnimalViewController.self) { r, c in
            c.animal = r.resolve(Animal.self)
        }
        defaultContainer.register(Animal.self) { _ in Cat(name: "Mimi") }
    }
}
```

#### Explicit Instantiation in AppDelegate

If you prefer explicit instantiation of UIWindow and its root view controller, instantiate `SwinjectStoryboard` with a container in `application:didFinishLaunchingWithOptions:` method.

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var container: Container = {
        let container = Container()
        container.storyboardInitCompleted(AnimalViewController.self) { r, c in
            c.animal = r.resolve(Animal.self)
        }
        container.register(Animal.self) { _ in Cat(name: "Mimi") }
        return container
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.makeKeyAndVisible()
        self.window = window

        let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil, container: container)
        window.rootViewController = storyboard.instantiateInitialViewController()

        return true
    }
}
```

Notice that you should delete the `Main storyboard file base name` item (or `UIMainStoryboardFile` item if you are displaying raw keys/values) in `Info.plist` of your app.

### Storyboard References

Storyboard Reference introduced with Xcode 7 is supported by `SwinjectStoryboard`. To enable dependency injection when an instance is created from a referenced storyboard, register dependencies to `defaultContainer` static property of `SwinjectStoryboard`.

```swift
let container = SwinjectStoryboard.defaultContainer
container.storyboardInitCompleted(AnimalViewController.self) { r, c in
    c.animal = r.resolve(Animal.self)
}
container.register(Animal.self) { _ in Cat(name: "Mimi") }
```

If you implicitly instantiate `UIWindow` and its root view controller, the registrations setup for "Main" storyboard can be shared with the referenced storyboard since `defaultContainer` is configured in `setup` method.

## Credits

SwinjectStoryboard is inspired by:

- [Typhoon](http://typhoonframework.org) - [Jasper Blues](https://github.com/jasperblues), [Aleksey Garbarev](https://github.com/alexgarbarev) and [contributors](https://github.com/appsquickly/Typhoon/graphs/contributors).
- [BlindsidedStoryboard](https://github.com/briancroom/BlindsidedStoryboard) - [Brian Croom](https://github.com/briancroom).

## License

MIT license. See the [LICENSE file](LICENSE.txt) for details.
