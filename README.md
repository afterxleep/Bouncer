Bouncer SMS Filter
=====================

This is a simple SMS filtering app for iOS that uses the ILMessageFilterExtension to move unwanted and specific messages to the "Junk", "Promotion" and "Transaction" sections of the Messages app. 

Different to other apps, Bouncer does not share, upload or send any of your personal information or SMS messages to a remote server.   All the filtering happens locally on your phone.

Messages text is checked against a simple user defined blacklist.

Features
----------------------
* Filter SMS messages using a simple list of words
* Catalog filtered messages in iOS 14+ categories (Junk, Transaction, Promotion)
* Unlimmited number of filter rules
* Automatic migration of filters from Version 1.x
* Localized in English and Spanish


Tech Stack/Specs
----------------------

Bouncer is written 100% in Swift, for iOS 14 and features things like:

* All new SwiftUI lifecycle (No storyboards or Appdelegate)
* Redux-like architecture
* Combine
* SwiftUI 2.x features and improvements
* Zero UIKit
* No 3rd party dependencies 💪

If you are curious about the architecture approach, check out my [Redux-like architecture with SwiftUI series](https://danielbernal.co/redux-like-architecture-with-swiftui-basics/)


Building
----------------------

Fire up XCode 12, open Bouncer.xcodeproj and hit Build.  There are no dependencies or additional requirements.

Latest Release
----------------------

The old 1.x version (UIkit based) is not avaiable from the App Store anymore, but you can grab the source and build it from [the 1.20 release].(https://github.com/afterxleep/Bouncer/releases/tag/v1.2.0).

Version 2.x (This new SwiftUI version) is [available in the App Store](https://apps.apple.com/us/app/bouncer-private-sms-blocker/id1457476313), and free to dowload


Contribute
----------------------

Please report any found issues or feed free to fork the repo and open pull requests with fixes, features or updates.

License
----------------------

Bouncer is distributed under [MIT license](https://github.com/afterxleep/Bouncer/blob/master/LICENSE)

