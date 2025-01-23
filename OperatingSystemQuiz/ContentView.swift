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
    @State private var finalScore:Int = 0
    @State private var selectedTopic:Topic?=nil
    
    var body: some View {
        VStack {
            if currentView=="login"{
                LoginView(currentView: $currentView)
            }
            else if currentView=="home"{
                HomeView(currentView: $currentView, selectedTopic: $selectedTopic)
            }
            else if currentView == "topicDetail"{
                if let topic = selectedTopic{
                    TopicDetailView(topic: topic, currentView: $currentView)
                }
            }
            else if currentView=="quiz"{
                if let topic = selectedTopic{
                    QuizView(currentView: $currentView, finalScore: $finalScore, topic: topic)
                }
            }
            else if currentView=="endPage"{
                EndPageView(currentView: $currentView, score: finalScore)
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
    
    @State private var showAlert:Bool=false
    
    var body: some View {
        VStack{
            Text("Login")
                .font(.largeTitle)
                .padding()
            
            TextField("User Name", text: $userName)
                .onSubmit {
                    if !userName.isEmpty &&
                        !email.isEmpty &&
                        isValidEmail(email){
                        showAlert=true
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Email", text: $email)
                .onSubmit {
                    if !userName.isEmpty &&
                        !email.isEmpty &&
                        isValidEmail(email){
                        showAlert=true
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action:{
                showAlert=true
            }){
                Text("Proceed")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.black)
                
            }
            .alert(isPresented: $showAlert){
                Alert(
                    title:Text("Start Proceeding"),
                    message: Text("Good luck, \(userName)!"),
                    dismissButton: .default(Text("OK"),action:{
                        currentView="home"
                    })
                )
            }
            .background(userName.isEmpty || email.isEmpty || !isValidEmail(email) ? Color.gray : Color.mint)
            .disabled(userName.isEmpty || email.isEmpty || !isValidEmail(email))
            .cornerRadius(10)
            .padding(.horizontal,40)
        }
        .padding()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx="[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest=NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}

struct HomeView: View {
    @Binding var currentView:String?
    @Binding var selectedTopic:Topic?
    
    var body: some View {
        VStack {
            Text("Operating Systems")
                .padding()
                .font(.largeTitle)
            
            ForEach(topics, id:\.name){
                topic in
                Button(topic.name)
                {
                    selectedTopic=topic
                    currentView="topicDetail"
                }
                .font(.headline)
                .padding()
                .foregroundColor(.black)
                .cornerRadius(10)
                .padding(.horizontal,20)
            }
        }
        .padding()
    }
}

struct TopicDetailView:View {
    let topic:Topic
    @Binding var currentView:String?
    
    var body: some View {
        VStack {
            Text(topic.name)
                .padding()
                .font(.headline)
            Text(topic.description)
                .padding()
            
            Button("Take Quiz"){
                currentView="quiz"
            }
            
            .font(.headline)
            .padding()
            .foregroundColor(.black)
            .background(.mint)
            .cornerRadius(10)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

struct Topic{
    let name:String
    let description:String
    let questions:[String:[String]]
    let correctAnswers:[String:String]
    
}


let topics: [Topic] = [
    Topic(
        name: "Process",
        description: "Process is the basic unit of execution in a computer system.",
        questions: [
            "What is a process?": ["A program in execution", "A stored file", "A network request", "A hardware device"],
            "What is process scheduling?": ["Allocating CPU to processes", "Managing storage", "Network requests", "Memory management"]
        ],
        correctAnswers: [
            "What is a process?": "A program in execution",
            "What is process scheduling?": "Allocating CPU to processes"
        ]
    ),
    Topic(
        name: "Kernel",
        description: "The kernel is the core part of an operating system.",
        questions: [
            "What is a kernel?": ["Core of an OS", "User interface", "File system", "Storage device"],
            "What is the role of the kernel?": ["Manage hardware", "Process emails", "Run apps", "Handle network requests"]
        ],
        correctAnswers: [
            "What is a kernel?": "Core of an OS",
            "What is the role of the kernel?": "Manage hardware"
        ]
    ),
    Topic(
        name: "Scheduling Algorithms",
        description: "Scheduling algorithms decide the order in which processes run.",
        questions: [
            "What is round-robin scheduling?": ["Equal time for processes", "Priority-based", "Shortest job first", "First come first served"],
            "What is the goal of scheduling?": ["Maximize CPU usage", "Save battery", "Reduce storage", "Improve graphics"]
        ],
        correctAnswers: [
            "What is round-robin scheduling?": "Equal time for processes",
            "What is the goal of scheduling?": "Maximize CPU usage"
        ]
    )
]

struct QuizView: View {
    
    @Binding var currentView:String?
    @Binding var finalScore:Int
    
    @State private var questionIndex=0
    @State private var score=0
    @State private var selectedAnswer:String?=nil
    @State private var isAnswerCorrect:Bool?=nil
    @State private var isAnswered=false
    @State private var confettiCounter:Int=0
    @State private var timeRemaining=15
    @State private var timer:Timer?=nil
    @Environment(\.colorScheme) var colorScheme
    let topic:Topic
    
    var body: some View{
        ScrollView{
            VStack{
                
                Text("Quiz: \(topic.name)")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
                
                HStack{
                    Text("Time Remaining: \(timeRemaining)")
                        .font(.headline)
                        .foregroundColor(timeRemaining<5 ? .red : .mint)
                        .padding()
                    
                    Spacer()
                    
                    Text("\(score)/\(topic.questions.count)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                }
                let question=Array(topic.questions.keys)[questionIndex]
                let answers=topic.questions[question]!
                
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
            
            if topic.correctAnswers[question] == option{
                isAnswerCorrect=true
                score+=1
                confettiCounter+=1
            }
            else{
                isAnswerCorrect=false
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+2){
                self.nextQuestion()
            }
        }
    }
    
    func backgroundColor(for option: String) -> Color {
        
        guard let selectedAnswer = selectedAnswer else{
            return colorScheme == .dark ? Color.mint : .white
        }
        if selectedAnswer == option {
            return isAnswerCorrect == true ? Color.green : Color.red
        }
        else{
            return colorScheme == .dark ? Color.mint : .white
        }
        
    }
    
    func nextQuestion() {
        if questionIndex+1>=topic.questions.count {
            stopTimer()
            finalScore=score
            currentView="endPage"
        }else{
            questionIndex+=1
            selectedAnswer = nil
            isAnswerCorrect = nil
            isAnswered=false
            //            resetTimer()
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



struct EndPageView: View {
    @Binding var currentView: String?
    let score: Int
    
    var body: some View {
        VStack {
            Text("🎉 Congratulations! 🎉")
                .font(.largeTitle)
                .padding()
            
            Text("You completed the quiz!")
                .font(.title)
                .padding(.bottom)
            
            Text("Your score: \(score)")
                .font(.title2)
                .padding()
            
            HStack(spacing: 20) {
                Button("Retake Quiz") {
                    currentView = "quiz"
                }
                .font(.headline)
                .padding()
                .background(Color.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
                Button("Home") {
                    currentView = "home"
                }
                .font(.headline)
                .padding()
                .background(Color.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top)
        }
        .padding()
    }
}




#Preview {
    ContentView()
}

