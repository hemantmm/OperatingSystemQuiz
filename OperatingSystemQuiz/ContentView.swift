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

struct HomeView: View {
    @Binding var currentView:String?
    
    var body: some View {
        VStack {
            Text("Operating Systems")
                .padding()
                .font(.largeTitle)
            
            Button("Process"){
                currentView="Process"
            }
            .font(.headline)
            .padding()
            .background(.mint)
            .foregroundColor(.black)
            .cornerRadius(10)
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

struct QuizView: View {
    @Binding var currnetView:String?
    
    @State private var questionIndex=0
    @State private var score=0
    @State private var showScoreAlert=false
    
    let questions=[
        "What is Process?":["A program in execution","A stored file","A netwok request","A hardware device"],
        "What is virtual memory?":["A memory managemant technique","A physical memory module","A storage disk","A network protocol"]
    ]
    
    var body: some View{
        VStack{
            if questionIndex<questions.count{
                let question=Array(questions.keys)[questionIndex]
                let answers=questions[question]!
                
                Text("Question \(questionIndex+1)!")
                
                Text(question)
            }
        }
    }
}

#Preview {
    ContentView()
}
