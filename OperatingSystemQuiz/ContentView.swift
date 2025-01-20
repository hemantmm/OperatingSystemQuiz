//
//  ContentView.swift
//  OperatingSystemQuiz
//
//  Created by Hemant Mehta on 20/01/25.
//

import SwiftUI

struct ContentView: View {
    
    
    var body: some View {
        VStack {
           
            Text("Hello, world!")
        }
        .padding()
    }
}

struct TopicDetailView:View {
    let topic:String
    let description:String
    
    @Binding var currentView:String?
    
    var body: some View {
        VStack {
            Text(topic)
                .padding()
                .font(.headline)
            Text(description)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
