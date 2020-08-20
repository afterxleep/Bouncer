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
            Text("'\(filter.phrase)'")
                    .bold()
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
        var data: FilterDestinationDecoration
        switch (filter.action) {
            case .junk:
                data = FilterDestination.junk.listDescription
            case .promotion:
                data = FilterDestination.promotion.listDescription
            case .transaction:
                data = FilterDestination.transaction.listDescription
            }
        return data
    }

    private func getFilterTypeColor(filter: Filter) -> Color {
        switch (filter.action) {
            case .junk:
                return COLORS.ALERT_COLOR
            case .promotion:
                return COLORS.WARNING_COLOR
            case .transaction:
                return COLORS.OK_COLOR
            }        
    }
}
