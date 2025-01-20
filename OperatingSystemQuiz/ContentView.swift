//
//  ContentView.swift
//  OperatingSystemQuiz
//
//  Created by Hemant Mehta on 20/01/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentView:String? = "home"
    
    var body: some View {
        VStack {
            if currentView=="home"{
                HomeView(currentView: $currentView)
            }
            else if currentView=="Process"{
                TopicDetailView(topic:"Process",description: "Process is the basic unit of execution in a computer system.",
                                currentView: $currentView)
            }
            else if currentView=="quiz"{
                QuizView(currentView: $currentView)
            }
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
            .foregroundColor(.black)
            .cornerRadius(10)
            
            Button("Process"){
                currentView="Process"
            }
            .font(.headline)
            .padding()
            .foregroundColor(.black)
            .cornerRadius(10)
            
            Button("Process"){
                currentView="Process"
            }
            .font(.headline)
            .padding()
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
            
            Button("Take Quiz"){
                currentView="quiz"
            }
            .font(.headline)
            .padding()
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .padding()
//        .background(.mint)
    }
}

struct QuizView: View {
    
    @Binding var currentView:String?
    
    @State private var questionIndex=0
    @State private var score=0
//    @State private var showScoreAlert=false
    @State private var selectedAnswer:String?=nil
    @State private var isAnswerCorrect:Bool?=nil
    @State private var isAnswered=false
    
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
                    .font(.headline)
                    .padding(.top)
                
                Text(question)
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
                
                ForEach(answers, id:\.self){
                    answer in
                    Button(action:{
                        guard !isAnswered else { return }
                        selectedAnswer = answer
                            isAnswered = true
                        if(question=="What is process?" && answer=="A program in exection") || (question=="What is virtual memory?" && answer=="A memory managemant technique"){
                            isAnswerCorrect=true
                            score+=1
                        }else{
                            isAnswerCorrect=false
                        }
//                            .background(.mint)
                        DispatchQueue.main.asyncAfter(deadline: .now()+2.0){
                            questionIndex+=1
                            selectedAnswer=nil
                            isAnswerCorrect=nil
                            isAnswered=false
                        }
                    })
                    {
                        Text(answer)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedAnswer==answer ? (isAnswerCorrect==true ? Color.green : Color.red) : nil)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                    }
                    .cornerRadius(10)
                    .disabled(isAnswered)
                }
            } else{
                Text("Quiz Completed!")
                    .font(.title)
                    .padding()
                
                Text("Your score is: \(score)/\(questions.count)")
                    .font(.headline)
                    .padding()
                
                Button("Back to Home Page"){
                    currentView="home"
                }
                .font(.headline)
                .padding()
                .foregroundColor(.black)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    
}

#Preview {
    ContentView()
}
