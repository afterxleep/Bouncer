//
//  MailView.swift
//  Bouncer
//
//  Created by Daniel on 23/04/23.
//

import Foundation
import SwiftUI
import MessageUI

struct ContactView: UIViewControllerRepresentable {
    @Binding var result: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactView>) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(["danielbernal@hey.com"])
        controller.setSubject("Bouncer Support (v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""))")
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<ContactView>) {
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: ContactView

        init(_ parent: ContactView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.result = false
            controller.dismiss(animated: true)
        }
    }
}
