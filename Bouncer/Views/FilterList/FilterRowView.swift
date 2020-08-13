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
            .foregroundColor(Color.red)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.red, lineWidth: 1)
                )
        }.padding(.vertical, 8)
        .font(.headline)
    }
    
}

extension FilterRowView {

    // MARK: - Helpers
    fileprivate func getFilterTypeDecoration(filter: Filter) -> SystemImage {
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
    
    fileprivate func getFilterDestinationDecoration(filter: Filter) -> FilterDestinationDecoration {
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
}
