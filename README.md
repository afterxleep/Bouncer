# Bouncer: SMS Filter for iOS

Welcome to **Bouncer**, a privacy-focused SMS filtering app for iOS devices. Utilizing the ILMessageFilterExtension, Bouncer organizes unwanted and specific messages into the "Junk", "Promotion", and "Transaction" sections of the Messages app.

## Prioritizing Privacy and Security

Unlike other SMS filtering apps, Bouncer does not share, upload, or send any of your personal information or SMS messages to a remote server. All filtering processes occur locally on your phone, ensuring data privacy and security.

## Customize Your Messaging Experience

Bouncer checks messages against a user-defined blacklist, providing a personalized and clutter-free messaging experience.

## Features
* Filter SMS messages using a simple list of words
* Categorize filtered messages in iOS 16+ sections (Junk, Transaction, Promotion) and subcategories
* Unlimited filter rules
* Localized in English, Spanish, and more
* Support for both word lists and regular (PCRE) expressions
* Import and export filter rules

## Latest Release

### Stable Version
Version 2.x is [available in the App Store](https://apps.apple.com/us/app/bouncer-private-sms-blocker/id1457476313).

### Try the Beta
Feeling adventurous? Join the [beta test group in TestFlight](https://testflight.apple.com/join/Lls6XUfx).

### Looking for an Older Version?
The older 1.x version (UIKit-based) is no longer available in the App Store, but you can obtain the source code and build it from [the 1.20 release](https://github.com/afterxleep/Bouncer/releases/tag/v1.2.0).

## Tech Stack/Specs
Bouncer is written entirely in Swift and features:

* SwiftUI lifecycle (no storyboards or AppDelegate)
* Redux-like architecture
* Combine framework
* SwiftUI 2.x features and improvements
* Zero UIKit dependency
* No third-party dependencies

For more information on the architectural approach, check out the [Redux-like architecture with SwiftUI series](https://danielbernal.co/redux-like-architecture-with-swiftui-basics/).

## Building
To build Bouncer, simply open Bouncer.xcodeproj in Xcode and click Build. No dependencies or additional requirements are needed.

## Contribute
Feel free to report any issues, fork the repo, and open pull requests with fixes, features, or updates.

## License
Bouncer is distributed under the [MIT license](https://github.com/afterxleep/Bouncer/blob/master/LICENSE).
