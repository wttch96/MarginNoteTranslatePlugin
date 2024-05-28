//
//  ContentView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI

struct ContentView: View {
    @State private var receviedUrl: String? = nil
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(receviedUrl)")
        }
        .padding()
        .onOpenURL(perform: { url in
            receviedUrl = url.absoluteString.removingPercentEncoding
        })
    }
}

#Preview {
    ContentView()
}
