//
//  BackgroundView.swift
//  Bouncer
//

import SwiftUI

struct BackgroundView: View {
    
    let color1 = Color(red: 0.235, green: 0.267, blue: 0.318)
    let color2 = Color(red: 0.07, green: 0.078, blue: 0.092)
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [color1, color2]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)
    }
}

struct BackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundView()
    }
}
