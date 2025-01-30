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
    @State private var userName:String=""
    @State private var leaderboard:[(name:String,score:Int)]=[]
    
    var body: some View {
        VStack {
            if currentView=="login"{
                LoginView(currentView: $currentView, userName: $userName)
            }
            else if currentView=="home"{
                HomeView(currentView: $currentView, selectedTopic: $selectedTopic, leaderboard: $leaderboard)
            }
            else if currentView=="dailyQuestionMode"{
                DailyQuestionModeView(currentView: $currentView, userName: $userName)
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
                EndPageView(currentView: $currentView, score: finalScore, userName: userName, leaderboard: $leaderboard)
            }
            else if currentView=="leaderboard"{
                LeaderboardView(currentView: $currentView, leaderboard: leaderboard)
            }
        }
        .padding()
    }
}

struct LoginView: View {
    
    @Binding var currentView:String?
    @Binding var userName:String
    @State private var email:String=""
    @State private var errorMessage:String=""
    @State private var userAgreed:Bool=false
    
    @State private var showAlert:Bool=false
    
    let agreementText:String="I have understood all the conditions written on the agreement and with adhere to them"
    
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
    @Binding var currentView: String?
    @Binding var selectedTopic: Topic?
    @Binding var leaderboard: [(name: String, score: Int)]
    @State private var animateIndex: Int = -1
    @State private var remainingTime: Int = 0 
    @State private var timerStarted: Bool = false

    @AppStorage("lastChallengeDate") private var lastChallengeDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Operating Systems")
                    .font(.largeTitle)
                    .padding()
                
                ForEach(topics.indices, id: \.self) { index in
                    TopicCardView(topic: topics[index]) {
                        selectedTopic = topics[index]
                        currentView = "topicDetail"
                    }
                    .offset(x: animateIndex >= index ? 0 : (index.isMultiple(of: 2) ? -300 : 300))
                    .opacity(animateIndex >= index ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.2), value: animateIndex)
                }
                .onAppear {
                    animateIndex = topics.count
                    updateRemainingTime()
                    startTimer()
                }

                Button("Daily Question Mode") {
                    currentView = "dailyQuestionMode"
                }
                .font(.headline)
                .padding()
                .foregroundColor(.black)
                .background(remainingTime > 0 ? Color.gray : Color.red)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                .disabled(remainingTime > 0)
                if remainingTime > 0 {
                    Text("Next challenge available in \(remainingTime) seconds")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                Button("View Leaderboard") {
                    currentView = "leaderboard"
                }
                .font(.headline)
                .padding()
                .foregroundColor(.black)
                .background(Color.mint)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }

    func updateRemainingTime() {
        // Only compute remaining time if the last challenge date exists
        guard let lastDate = lastChallengeDate else {
            remainingTime = 0 // No previous challenge, enable the button
            return
        }
        
        let timeInterval = Date().timeIntervalSince(lastDate)
        remainingTime = max(0, 86400 - Int(timeInterval)) // 86400 seconds = 24 hours
    }

    func startTimer() {
        // Only start the timer if it's not already started
        if !timerStarted {
            timerStarted = true
            // Timer to decrement the remaining time every second
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if remainingTime > 0 {
                    remainingTime -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}



struct DailyQuestionModeView: View {
    @Binding var currentView: String?
    @Binding var userName: String
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var isAnswered = false
    @State private var selectedAnswer: String? = nil
    @State private var isAnswerCorrect: Bool? = nil
    @State private var confettiCounter: Int = 0
    @State private var timeRemaining = 20 // Set initial timer to 20 seconds

    
    @AppStorage("lastChallengeDate") private var lastChallengeDate: Date?

    let challengeQuestions: [String: [String]] = [
        "What is the main function of the operating system kernel?": ["Manage hardware resources", "Run applications", "Provide internet access", "Store files"],
        "What scheduling algorithm gives equal time to all processes?": ["Round-robin", "First Come First Serve", "Shortest Job First", "Priority Scheduling"],
        "Which of the following is not an operating system?": ["Microsoft Word", "Windows 10", "Linux", "macOS"]
    ]
    
    let correctAnswers: [String: String] = [
        "What is the main function of the operating system kernel?": "Manage hardware resources",
        "What scheduling algorithm gives equal time to all processes?": "Round-robin",
        "Which of the following is not an operating system?": "Microsoft Word"
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Daily Question Mode")
                    .font(.largeTitle)
                    .padding()
                
                Text("Time Remaining: \(timeRemaining) seconds")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()

                let question = Array(challengeQuestions.keys)[questionIndex]
                let answers = challengeQuestions[question]!

                Text(question)
                    .font(.title2)
                    .padding()
                    .multilineTextAlignment(.center)

                ForEach(answers, id: \.self) { answer in
                    Button(action: {
                        guard !isAnswered else { return }
                        selectOption(answer, for: question)
                    }) {
                        Text(answer)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                            .background(backgroundColor(for: answer))
                            .cornerRadius(10)
                            .padding(.horizontal, 10)
                            .disabled(isAnswered)
                    }
                }
                
                if let isAnswerCorrect = isAnswerCorrect {
                    Text(isAnswerCorrect ? "Correct!" : "Incorrect")
                        .font(.title)
                        .foregroundColor(isAnswerCorrect ? .green : .red)
                        .padding()
                }
            }
            .padding()
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
        
        ConfettiCannon(trigger: $confettiCounter, num: 50, colors: [.red, .blue, .green], radius: 300.0)
    }
    
    func selectOption(_ option: String, for question: String) {
        if selectedAnswer == nil {
            selectedAnswer = option
            isAnswered = true
            if correctAnswers[question] == option {
                isAnswerCorrect = true
                score += 1
                confettiCounter += 1
            } else {
                isAnswerCorrect = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                nextQuestion()
            }
        }
    }
    
    func nextQuestion() {
        if questionIndex + 1 >= challengeQuestions.count {
            stopTimer()
            lastChallengeDate=Date()
            currentView="home"
        } else {
            questionIndex += 1
            selectedAnswer = nil
            isAnswerCorrect = nil
            isAnswered = false
        }
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    func stopTimer() {
        // Logic to stop the timer, if needed
    }
    
    func backgroundColor(for option: String) -> Color {
        guard let selectedAnswer = selectedAnswer else {
            return .white
        }
        if selectedAnswer == option {
            return isAnswerCorrect == true ? Color.green : Color.red
        } else {
            return .white
        }
    }

    func isButtonEnabled() -> Bool {
        guard let lastDate = lastChallengeDate else {
            return true
        }
        
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(lastDate)
        
        return timeInterval >= 86400
    }
}




struct TopicCardView: View {
    let topic: Topic
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(topic.name)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(.easeOut(duration: 0.5), value: isVisible)
            Text(topic.description)
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(colorScheme == .dark ? Color.green
                                 : Color.orange)
                .opacity(isVisible ? 1 : 0)
                .offset(y:isVisible ? 0 : -20)
                .animation(.easeIn(duration: 1), value: isVisible)
            Button(action: action) {
                Text("Learn More")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .background(colorScheme == .dark ? Color.mint : Color.blue)
                    .cornerRadius(10)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : -20)
            .animation(.easeInOut(duration: 1.5), value: isVisible)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.purple : Color.white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 8, x: 0, y: 5
                )
        )
        .padding(.horizontal)
        .onAppear{
            withAnimation{
                isVisible=true
            }
        }
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
    
    @Binding var currentView: String?
    @Binding var finalScore: Int
    
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var adjustedScore = 0.0
    @State private var selectedAnswer: String? = nil
    @State private var isAnswerCorrect: Bool? = nil
    @State private var isAnswered = false
    @State private var confettiCounter: Int = 0
    @State private var timeRemaining = 15
    @State private var timer: Timer? = nil
    @State private var hintUsed: Bool = false
    @State private var hintAvailable:Bool=false
    @State private var hintText: String? = nil
    @Environment(\.colorScheme) var colorScheme
    let topic: Topic
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Quiz: \(topic.name)")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
                
                HStack {
                    Text("Time Remaining: \(timeRemaining)")
                        .font(.headline)
                        .foregroundColor(timeRemaining < 5 ? .red : .mint)
                        .padding()
                    
                    Spacer()
                    
                    Text("\(Int(adjustedScore))/\(topic.questions.count)") // Use adjustedScore for display
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                let question = Array(topic.questions.keys)[questionIndex]
                let answers = topic.questions[question]!
                
                Text(question)
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
                
                ForEach(answers, id: \.self) { answer in
                    Button(action: {
                        guard !isAnswered else { return }
                        selectOption(answer, for: question)
                    }) {
                        Text(answer)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                    }
                    .background(backgroundColor(for: answer))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .disabled(isAnswered)
                }
                
                if hintAvailable && !hintUsed {
                    Button(action: {
                        hintUsed = true
                        hintText = "Here's a hint: \(getHint(for: question))"
                        adjustedScore = max(adjustedScore - 1, 0) // Deduct 0.5 from adjustedScore
                    }) {
                        Text("Hint")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                           
                            
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.yellow)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.bottom, 10)
                }
                
                if let hintText = hintText {
                    Text(hintText)
                        .font(.body)
                        .foregroundColor(.orange)
                        .padding(.bottom)
                }
            }
            .padding()
            .onAppear {
                startTimer()
                startHintTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
        ConfettiCannon(trigger: $confettiCounter, num: 50, colors: [.red, .blue, .green], radius: 300.0)
    }
    
    func getHint(for question: String) -> String {
        guard let correctAnswer = topic.correctAnswers[question] else { return "No hint available" }
        return "The correct answer starts with: \(correctAnswer.prefix(1))"
    }
    
    func selectOption(_ option: String, for question: String) {
        if selectedAnswer == nil {
            selectedAnswer = option
            isAnswered = true
            
            if topic.correctAnswers[question] == option {
                isAnswerCorrect = true
                adjustedScore += 1
                confettiCounter += 1
            } else {
                isAnswerCorrect = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.nextQuestion()
            }
        }
    }
    
    func backgroundColor(for option: String) -> Color {
        guard let selectedAnswer = selectedAnswer else {
            return colorScheme == .dark ? Color.mint : .white
        }
        if selectedAnswer == option {
            return isAnswerCorrect == true ? Color.green : Color.red
        } else {
            return colorScheme == .dark ? Color.mint : .white
        }
    }
    
    func nextQuestion() {
        if questionIndex + 1 >= topic.questions.count {
            stopTimer()
            finalScore = Int(adjustedScore) // Set finalScore to the adjusted score
            currentView = "endPage"
        } else {
            questionIndex += 1
            selectedAnswer = nil
            isAnswerCorrect = nil
            isAnswered = false
            hintUsed = false
            hintAvailable=false
            hintText = nil
            startHintTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                nextQuestion()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func startHintTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now()+5){
            if !isAnswered{
                hintAvailable=true
            }
        }
    }
}





struct EndPageView: View {
    @Binding var currentView: String?
    let score: Int
    let userName:String
    @State private var isUserNameEntered:Bool=false
    
    @Binding var leaderboard:[(name:String,score:Int)]
    
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
            
            Text("Thanks, \(userName)")
                .font(.title2)
                .padding()

            HStack(spacing: 20) {
                Button("Retake Quiz", systemImage: "restart.circle") {
                    currentView = "quiz"
                }
                .font(.headline)
                .padding()
                .background(Color.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
                Button("Home Page", systemImage: "house.fill") {
                    currentView = "home"
                }
                .font(.headline)
                .padding()
                .background(Color.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
                Button("View Leaderboard"){
                    saveScoreToLeaderboard()
                    currentView="leaderboard"
                }
                .font(.headline)
                .padding()
                .background(.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func saveScoreToLeaderboard() {
        if let existingIndex=leaderboard.firstIndex(where:{$0.name == userName}){
            if leaderboard[existingIndex].score<score{
                leaderboard[existingIndex].score=score
            }
        }
        else{
            leaderboard.append((name:userName,score:score))
        }
        leaderboard.sort{$0.score > $1.score}
    }
}

struct LeaderboardView: View {
    @Binding var currentView: String?
    let leaderboard: [(name: String, score: Int)]
    
    var body: some View {
        VStack {
            Text("Leaderboard")
                .font(.largeTitle)
                .padding()
            
            List {
                ForEach(leaderboard, id: \.name) { entry in
                    HStack {
                        Text(entry.name)
                            .font(.headline)
                        Spacer()
                        Text("\(entry.score)")
                            .font(.subheadline)
                    }
                    .padding()
                }
            }
            Button("Homepage", systemImage: "homekit") {
                currentView = "home"
            }
            .font(.headline)
            .padding()
            .background(.mint)
            .foregroundColor(.black)
            .cornerRadius(10)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}


#Preview {
    ContentView()
}

