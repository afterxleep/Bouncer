Privacy Policy
=====================

Bouncer requires read access to your SMS messages and sender information to perform filtering.

Filtering happens on your iPhone. Your messages and their contents are filtered entirely on the device and never leave it. Not to Bouncer, not to anyone. Bouncer does not upload or send SMS messages or message contents to a remote server, and developers or third parties will never have access to such data. Sender information is different: when you create, change, or delete a rule whose phrase is a sender pattern, the rule itself — including that phrase — is sent to a server operated by the developer, as described below. The app does not store local copies of your messages or their contents, and message filtering happens in real time when your messages reach your phone.

What is sent. When you create, change, or delete a rule, Bouncer sends that rule to a server operated by the developer. Each rule contains a unique id, the phrase or sender pattern you wrote, the sender scope you chose (anywhere, sender, or message text), the destination (Safe, Junk, or a category such as Orders), whether it is a regular expression, and whether it is case sensitive. Rules are tied to a timestamp and to your device's general language and region (for example, "en_US"). Non-regex rules do a case-insensitive substring match by default, which is what most people mean by "exact match" — case sensitivity is an opt-in for that path.

What is not sent. Bouncer does not send your messages, your contacts, your phone number, your Apple ID, your location, your advertising identifier, or any other identifier that can be used to track you across apps. Analytics are not linked to a user account and are not used for advertising.

Bouncer is designed with privacy in mind, will always be open source, and will never track you across apps or services. The data above is the only data Bouncer sends to the developer's server. Like every network request, that HTTPS POST necessarily exposes some network metadata — for example your device's IP address, the connection timestamp, and the TLS handshake that the transport layer carries — to the operators of any network the request traverses, including Apple's and your carrier's, and Bouncer also exchanges requests with Apple to fulfil StoreKit transactions.
