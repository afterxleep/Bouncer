Bouncer SMS Filter
=====================

This is a simple SMS filtering app for iOS that uses the ILMessageFilterExtension to move unwanted messages to the "Junk" Section.

Different to other apps, Bouncer does not share, upload or send any of your personal information or SMS messages to a remote server.   All the filtering happens locally on your phone.

Messages text is checked against a simple user defined blacklist.

Features
----------------------
* Filter SMS messages using a simple list of words
* Catalog filtered messages in iOS 14+ categories (Junk, Transaction, Promotion)
* Unlimmited number of filter rules
* Automatic migration of filters from Version 1.x
* Localized in English and Spanish


Tech Stack
----------------------
Bouncer is written 100% in Swift, for iOS 14 and features things like:

* All new SwiftUI lifecycle (No storyboards, Appdelegate or UIKit)
* Redux-like architecture
* Combine
* SwiftUI 2.x features and improvements


Building
----------------------

Fire up XCode 12 (Currently beta), open Bouncer.xcodeproj and hit Build.  There are no dependencies or additional requirements.

Note: This version is a complete Rewrite Using SwiftUI 2.0, so you will need Xcode 12 and an an iOS 14 Device to run it.

Latest Release
----------------------

The old version (UIkit based) is available from the [App Store](https://apps.apple.com/us/app/bouncer-sms-block-list/id1457476313) for free.  
This version will be released when iOS 14 becomes available to the public.


Contribute
----------------------

Please report any found issues or feed free to fork the repo and open pull requests with fixes, features or updates.

License
----------------------

Bouncer is distributed under [MIT license](https://github.com/afterxleep/Bouncer/blob/master/LICENSE)

