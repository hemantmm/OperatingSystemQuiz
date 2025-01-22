//
//  ContentView.swift
//  OperatingSystemQuiz
//
//  Created by Hemant Mehta on 20/01/25.
//

import SwiftUI
import ConfettiSwiftUI

struct ContentView: View {
    @State private var currentView:String? = "login"
    
    var body: some View {
        VStack {
            if currentView=="login"{
                LoginView(currentView: $currentView)
            }
            else if currentView=="home"{
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

struct LoginView: View {
    
    @Binding var currentView:String?
    @State private var userName:String=""
    @State private var email:String=""
    @State private var errorMessage:String=""
    
    var body: some View {
        VStack{
            Text("Login")
                .font(.largeTitle)
                .padding()
            
            TextField("User Name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if !errorMessage.isEmpty{
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button(action:{
                if userName.isEmpty || email.isEmpty{
                    errorMessage="Please fill all the fields"
                }else{
                    errorMessage=""
                    currentView="home"
                }
            }){
                Text("Proceed")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.black)
                    
            }
            .background(Color.mint)
            .cornerRadius(10)
            .padding(.horizontal,40)
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
            
//            Button("Process"){
//                currentView="Process"
//            }
//            .font(.headline)
//            .padding()
//            .foregroundColor(.black)
//            .cornerRadius(10)
//
//            Button("Process"){
//                currentView="Process"
//            }
//            .font(.headline)
//            .padding()
//            .foregroundColor(.black)
//            .cornerRadius(10)
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
    }
}

struct QuizView: View {
    
    @Binding var currentView:String?
    
    @State private var questionIndex=0
    @State private var score=0
    @State private var selectedAnswer:String?=nil
    @State private var isAnswerCorrect:Bool?=nil
    @State private var isAnswered=false
    @State private var confettiCounter:Int=0
    @State private var timeRemaining=15
    @State private var timer:Timer?=nil
    
    let questions=[
        "What is process?":["A program in execution","A stored file","A network request","A hardware device"],
        "What is virtual memory?":["A memory management technique","A physical memory module","A storage disk","A network protocol"]
    ]
    
    var body: some View{
        ScrollView{
            VStack{
                if questionIndex<questions.count{
                    let question=Array(questions.keys)[questionIndex]
                    let answers=questions[question]!
                    
                    HStack{
                        Text("Question \(questionIndex+1)!")
                            .font(.headline)
                            .padding(.top)
                        Spacer()
                        
                        Text("Time remaining: \(timeRemaining) seconds")
                            .font(.headline)
                            .foregroundColor(timeRemaining<5 ? .red : .mint)
                    }
                    
                    Text(question)
                        .font(.title3)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    ForEach(answers, id:\.self){
                        answer in
                        Button(action:{
                            guard !isAnswered else { return }
                            selectOption(answer,for:question)
                        }){
                            Text(answer)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                        }
                        .background(backgroundColor(for: answer))
                        .cornerRadius(10)
                        .padding(.horizontal,10)
                        .disabled(isAnswered)
                    }
                }
                
                else{
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
            .onAppear{
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
        ConfettiCannon(trigger: $confettiCounter,num:50,colors:[.red,.blue,.green],radius:300.0)
    }
    
    func selectOption(_ option:String, for question:String){
                            if selectedAnswer == nil{
                                selectedAnswer=option
                                isAnswered=true
                                
                                if (question=="What is process?" && option=="A program in execution") || (question=="What is virtual memory?" && option=="A memory management technique"){
                                    isAnswerCorrect=true
                                    score+=1
                                    confettiCounter+=1
                                } else{
                                    isAnswerCorrect=false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now()+2){
                                    questionIndex+=1
                                    selectedAnswer=nil
                                    isAnswerCorrect=nil
                                    isAnswered=false
                                }
                            }
                        }
                               
    func backgroundColor(for option: String) -> Color {
        if let selectedAnswer = selectedAnswer {
            if selectedAnswer == option {
                return isAnswerCorrect == true ? Color.green : Color.red
            }
        }
        return Color.mint
    }
    
    func nextQuestion() {
        if questionIndex+1>=questions.count {
            stopTimer()
        }else{
            questionIndex+=1
            selectedAnswer = nil
            isAnswerCorrect = nil
            isAnswered=false
            resetTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){ _ in
            if timeRemaining>0 {
                timeRemaining-=1
            }
            else{
                nextQuestion()
            }
        }
    }
    
    func resetTimer() {
        timeRemaining = 15
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer=nil
    }
}



#Preview {
    ContentView()
}

