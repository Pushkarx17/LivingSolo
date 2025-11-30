//
//  AboutView.swift
//  LivingSolo
//
//  Created by Pushkar K U on 10/11/2025.
//

import SwiftUI

struct AboutView: View {

    var body: some View {
        NavigationView {
            Form {

                Text("Pushkar K U")
            }
            .navigationTitle(Text("About"))
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
