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
            .font(.caption)
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
                        return FilterDestination.promotionOther.listDescription
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
                        return FilterDestination.transactionOther.listDescription
                }
            case .junk:
                return FilterDestination.junk.listDescription
            case .none:
            return FilterDestination.none.listDescription

            default:
                return FilterDestination.junk.listDescription
            }
    }

    private func getFilterTypeColor(filter: Filter) -> Color {
        if filter.subAction == .none {
            switch (filter.action) {
                case .promotion:
                    return COLORS.PALLETE_1
                case .transaction:
                    return COLORS.PALLETE_4
                case .junk:
                    return COLORS.ALERT_COLOR
                default:
                    return COLORS.OK_COLOR
            }
        } else {
            switch (filter.subAction) {
                case .promotionOther:
                    return COLORS.PALLETE_1
                case .promotionOffers:
                    return COLORS.PALLETE_2
                case .promotionCoupons:
                    return COLORS.PALLETE_3
                case .transactionOrder:
                    return COLORS.PALLETE_4
                case .transactionOther:
                    return COLORS.PALLETE_5
                case .transactionFinance:
                    return COLORS.PALLETE_6
                case .transactionReminders:
                    return COLORS.PALLETE_7
                default:
                    return COLORS.OK_COLOR
            }
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
