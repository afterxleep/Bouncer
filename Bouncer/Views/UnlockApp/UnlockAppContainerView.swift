//
//  UnlockAppContainerView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/15/20.
//

import SwiftUI

struct UnlockAppContainerView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        UnlockAppView(closeButtonTapped: closeSheet,
                      restoreButtonTapped: restorePurchases,
                      purchaseTapped: purchaseProduct,
                      products: store.state.inApp.availableProducts,
                      transactionInprogress: store.state.inApp.transactionInProgress)
    }
}

struct UnlockAppContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockAppContainerView()
    }
}

extension UnlockAppContainerView {

    func closeSheet() {

    }

    func restorePurchases() {

    }

    func purchaseProduct(product: Product) {

    }

}
