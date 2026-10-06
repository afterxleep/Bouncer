---
title: "Bouncer Rule Workflow"
description: "How to create a message-filter rule, including sender area-code matching."
keywords: ["filter rule", "area code", "sender", "FilterDetailView", "SMSOfflineFilter"]
topics: ["message-filtering"]
category: "ios"
filePatterns: ["Bouncer/Views/FilterDetail/FilterDetailView.swift", "Bouncer/Models/SMSFilter/SMSOfflineFilter.swift"]
---

# Bouncer Rule Workflow

## Filter an area code

Create a rule, enter `309` as the text to match, choose **Sender** under **Look in**, select the destination (for example, **Junk**), and save. Sender rules use a case-insensitive substring match by default, so the rule matches sender numbers containing `309`, including common US number formats.

Choose **Sender**, rather than **Anywhere**, so a message body that merely mentions `309` does not match. The matching implementation is `Bouncer/Models/SMSFilter/SMSOfflineFilter.swift` → `applyFilter(filter:message:)`.

## iOS message-filter limits

iOS only sends eligible messages from unknown senders to third-party text-message filters. A sender saved in Contacts, marked as known, or replied to three or more times is not eligible; use the system block/report controls for those senders instead. In Messages, turn on **Screen Unknown Senders** and then enable **Text Message Filter** and Bouncer under **Manage Filtering** before testing the rule.
