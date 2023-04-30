//
//  FilterRow.swift
//  Bouncer
//

import Foundation
import SwiftUI

struct FilterRowView: View {
    var filter: Filter
    
    var body: some View {
        let typeDecoration = getFilterTypeDecoration(filter: filter)
        let actionDecoration = getFilterDestinationDecoration(filter: filter)
        let typeColor = getFilterTypeColor(filter: filter)
        HStack(spacing: 10) {
            Image(systemName: typeDecoration.image)
                .foregroundColor(.gray)
                .aspectRatio(contentMode: .fit)
            getFilterText(filter: filter)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: actionDecoration.decoration.image)
                Text(actionDecoration.text)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .foregroundColor(COLORS.DEFAULT_COLOR)
            .background(typeColor)
            .cornerRadius(5)
        }.padding(.vertical, 8)
        .font(.headline)
    }
    
}

extension FilterRowView {

    // MARK: - Helpers
    private func getFilterTypeDecoration(filter: Filter) -> SystemImage {
        var data: SystemImage
        switch(filter.type) {
            case .sender:
                data = FilterType.sender.listDescription
            case .message:
                data = FilterType.message.listDescription
            default:
                data = FilterType.any.listDescription
        }
        return data
    }
    
    private func getFilterDestinationDecoration(filter: Filter) -> FilterDestinationDecoration {
        switch (filter.action) {
            case .promotion:
                switch filter.subAction {
                    case .promotionOffers:
                        return FilterDestination.promotionOffers.listDescription
                    case .promotionCoupons:
                        return FilterDestination.promotionCoupons.listDescription
                    default:
                        return FilterDestination.promotion.listDescription
                }
            case .transaction:
                switch filter.subAction {
                    case .transactionReminders:
                        return FilterDestination.transactionReminders.listDescription
                    case .transactionFinance:
                        return FilterDestination.transactionFinance.listDescription
                    case .transactionOrder:
                        return FilterDestination.transactionOrder.listDescription
                    default:
                        return FilterDestination.transaction.listDescription
                }
            case .junk:
                return FilterDestination.junk.listDescription
            default:
                return FilterDestination.junk.listDescription
            }
    }

    private func getFilterTypeColor(filter: Filter) -> Color {
        switch (filter.action) {
            case .junk, .none:
                return COLORS.ALERT_COLOR
            case .promotion, .promotionOther, .promotionOffers, .promotionCoupons:
                return COLORS.WARNING_COLOR
            case .transaction, .transactionOrder, .transactionOther, .transactionFinance, .transactionReminders:
                return COLORS.OK_COLOR
            default:
                return COLORS.ALERT_COLOR
            }        
    }
    
    private func getFilterText(filter: Filter) -> Text {
        if filter.useRegex {
            return Text("/\(filter.phrase)/")
                .bold()
        }
        return Text("'\(filter.phrase)'")
                .bold()
    }
}
