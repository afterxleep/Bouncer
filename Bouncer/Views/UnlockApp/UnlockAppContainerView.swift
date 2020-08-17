//
//  UnlockAppContainerView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/15/20.
//

import SwiftUI

struct UnlockAppContainerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: AppStore

    var body: some View {
        UnlockAppView(closeButtonTapped: closeSheet,
                      restoreButtonTapped: restorePurchases,
                      purchaseTapped: purchaseProduct,
                      products: store.state.inApp.availableProducts,                      
                      transactionInprogress: store.state.inApp.transactionInProgress,
                      maximumFreeFilters: store.state.settings.maximumFreeFilters
        ).onAppear(perform: fetchProducts)
    }
}

struct UnlockAppContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockAppContainerView()
    }
}

extension UnlockAppContainerView {

    func fetchProducts() {
        store.dispatch(.inApp(action: .fetchProducts))
    }

    func closeSheet() {
        presentationMode.wrappedValue.dismiss()
    }

    func restorePurchases() {

    }

    func purchaseProduct(product: Product) {

    }

}
