//
//  ContentView.swift
//  OperatingSystemQuiz
//
//  Created by Hemant Mehta on 20/01/25.
//

import SwiftUI
import ConfettiSwiftUI
import AVKit


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}


struct ContentView: View {
    @State private var currentView:String? = "login"
    @State private var finalScore:Int = 0
    @State private var selectedTopic:Topic?=nil
    @State private var userName:String=""
    @State private var userInitial:String=""
//    @State private var leaderboard:[(name:String,score:Int, topics:[String])]=[]
    @State private var leaderboard:[(name:String,topics:[(topic:String,score:Int)])]=[]
    let totalQuizzes:Int=4
    
    var body: some View {
        VStack {
            if currentView=="login"{
                LoginView(currentView: $currentView, userName: $userName, userInitial: $userInitial)
            }
            else if currentView=="home"{
                HomeView(currentView: $currentView, selectedTopic: $selectedTopic, leaderboard: $leaderboard, userInitial: $userInitial, userName:$userName)
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
                EndPageView(currentView: $currentView, score: finalScore, userName: userName, selectedTopic: $selectedTopic, leaderboard: $leaderboard)
            }
            else if currentView=="leaderboard"{
                LeaderboardView(currentView: $currentView, leaderboard: leaderboard, totalQuizzes: totalQuizzes)
            }
        }
        .padding()
    }
}

struct LoginView: View {
    
    @Binding var currentView:String?
    @Binding var userName:String
    @Binding var userInitial:String
    @State private var email:String=""
    @State private var errorMessage:String=""
    @State private var userAgreed:Bool=false
    
    @State private var showAlert:Bool=false
    
    let agreementText:String="I have understood all the conditions written on the agreement and with adhere to them"
    
    var body: some View {
        ZStack{
            //                Image("loginbackground")
            //                .resizable()
            //                .scaledToFill()
            //                .edgesIgnoringSafeArea(.all)
            VStack{
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(.purple)
                
                TextField("Enter name", text: $userName)
                    .placeholder(when: userName.isEmpty){
                        Text("")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .onSubmit {
                        handleuserLogo()
                    }
                    .padding(.leading,10)
//                    .background(.purple.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.title)
                    .padding()
                
                TextField("Enter email", text: $email, axis: .horizontal)
                    .placeholder(when:email.isEmpty){
                        Text("")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .onSubmit {
                        handleuserLogo()
                    }
                    .padding(.leading,10)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.title)
                //                    .shadow(color: .red ,radius: 5,x:0,y:0)
                    .padding()
                
                Button(action: {
                    handleuserLogo()
                }) {
                    Text("Proceed")
                        .font(.title2)
                        .padding()
                }
                .background(userName.isEmpty || email.isEmpty || !isValidEmail(email) ? Color.gray : Color.purple)
                .disabled(userName.isEmpty || email.isEmpty || !isValidEmail(email))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .foregroundColor(.white)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Start Proceeding"),
                        message: Text("Good luck, \(userName)!"),
                        dismissButton: .default(Text("OK"), action: {
                            currentView = "home"
                        })
                    )
                }
                
                //                .background(userName.isEmpty || email.isEmpty || !isValidEmail(email) ? Color.gray : Color.purple)
                //                .disabled(userName.isEmpty || email.isEmpty || !isValidEmail(email))
                
            }
            .padding()
        }
    }
    
    private func handleuserLogo(){
        if !userName.isEmpty && !email.isEmpty && isValidEmail(email){
            userInitial=String(userName.prefix(1)).uppercased()
            showAlert=true
        }
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
    @Binding var leaderboard: [(name: String,topics:[(topic:String,score:Int)])]
    @Binding var userInitial: String
    @Binding var userName:String
    @State private var animateIndex: Int = -1
    @State private var remainingTime: Int = 0
    @State private var timerStarted: Bool = false
    @State private var showDropdown: Bool = false
    @State private var userLogoColor:Color=generateRandomColor()

    @AppStorage("lastChallengeDate") private var lastChallengeDate: Date?

    var body: some View {
        
        
        HStack {
            Spacer()
            Button(action: {
                showDropdown.toggle()
            }) {
                Circle()
                    .fill(userLogoColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(userInitial)
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.purple)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .popover(isPresented: $showDropdown) {
                VStack {
                    Button("Logout") {
                        userName=""
                        userInitial=""
                        userLogoColor=generateRandomColor()
                        currentView = "login"
                    }
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        
        
        ScrollView {
            VStack(spacing: 20) {
                Text("Operating Systems")
                    .font(.largeTitle)
                    .padding()
                    .fontWeight(.bold)
//                    .background(.purple)
                
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
                .foregroundColor(.white)
                .background(Color.yellow.opacity(0.7))
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                .fontWeight(.bold)
            }
            .padding()
        }
        .background(.purple)
//        .background(.orange)
    }
    

    func updateRemainingTime() {
        guard let lastDate = lastChallengeDate else {
            remainingTime = 0
            return
        }
        
        let timeInterval = Date().timeIntervalSince(lastDate)
        remainingTime = max(0, 86400 - Int(timeInterval))
    }

    func startTimer() {
        if !timerStarted {
            timerStarted = true
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

func generateRandomColor() -> Color {
    Color(red: Double.random(in: 0...1),
          green: Double.random(in: 0...1),
          blue: Double.random(in: 0...1)
    )
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


struct TopicCardView: View{
    let topic: Topic
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isVisible: Bool = false
    
    var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(topic.name)
                        .font(.title2)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : -20)
                        .animation(.easeOut(duration: 0.5), value: isVisible)
                        .fontWeight(.heavy)
                    
                    Button(action: action) {
                        Text("Learn More")
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                            .background(colorScheme == .dark ? Color.white : Color.purple)
                            .cornerRadius(10)
                            .fontWeight(.bold)
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(.easeInOut(duration: 1.5), value: isVisible)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(colorScheme == .dark ? Color.yellow.opacity(0.7) : Color.white.opacity(0.8))
//                    .fill(colorScheme == .dark ? Color.pink.opacity(0.7) : Color.white.opacity(0.8))
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                        radius: 8, x: 0, y: 5
                    )
            )
            .padding(.horizontal)
            .onAppear {
                withAnimation {
                    isVisible = true
                }
            }
        }
}


struct TopicDetailView:View {
    let topic:Topic
    @Binding var currentView:String?
    @State private var isVideoPlaying=false
    
    var body: some View {
        ZStack{
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
                .foregroundColor(.white)
                .background(.purple)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .blur(radius: isVideoPlaying ? 10 : 0)
            
            if isVideoPlaying{
                ZStack{
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VideoPlayerView(videoName: "\(topic.name.lowercased())_background", isPlaying: $isVideoPlaying)
                        .frame(width: 300, height: 300)
                        .cornerRadius(10)
                }
            }
        }
        .toolbar{
            ToolbarItem(placement: .automatic){
                Button(action: {
                    isVideoPlaying=true
                }){
                    Image(systemName: "video.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}


//struct TopicDetailView: View {
//    let topic: Topic
//    @Binding var currentView: String?
//
//    var body: some View {
//        HStack {
//            // Left side: Text
//            VStack(alignment: .leading, spacing: 20) {
//                Text(topic.name)
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .foregroundColor(.purple)
//                Text(topic.description)
//                    .font(.body)
//                    .foregroundColor(.black)
//
//                Button("Take Quiz") {
//                    currentView = "quiz"
//                }
//                .font(.headline)
//                .padding()
//                .foregroundColor(.white)
//                .background(Color.purple)
//                .cornerRadius(10)
//                .buttonStyle(PlainButtonStyle())
//            }
//            .padding()
//            .frame(maxWidth: .infinity, alignment: .leading)
//
//            // Right side: Video
//            if let url = Bundle.main.url(forResource: "\(topic.name.lowercased())_background", withExtension: "mp4") {
//                VideoPlayer(player: AVPlayer(url: url))
//                    .frame(width: 300, height: 300)
//                    .cornerRadius(10)
//                    .padding()
//            } else {
//                Text("Video not found")
//                    .foregroundColor(.red)
//                    .padding()
//            }
//        }
//        .padding()
//    }
//}


struct VideoPlayerView: View {
    let videoName:String
    @Binding var isPlaying:Bool
    
    var body: some View {
        ZStack{
            if let url=Bundle.main.url(forResource: videoName, withExtension: "mp4"){
                VideoPlayer(player:AVPlayer(url: url))
                    .onDisappear {
                        isPlaying=false
                    }
            }
            else{
                Text("Video not found")
                    .foregroundColor(.purple)
                    .padding()
            }
            VStack{
                HStack{
                    Spacer()
                    Button(action:{
                        isPlaying=false
                    }){
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                            .padding()
                    }
                }
                Spacer()
            }
        }
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
        description: "Connection between hardware and software",
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
    ),
    Topic(
        name: "Deadlock",
        description: "Deadlock is a situation in computing where two or more processes are unable to proceed because each is waiting for the other to release resources.",
        questions: [
            "Which one of the following is the deadlock avoidance algorithm?": ["banker’s algorithm", "round-robin algorithm", "elevator algorithm", "First come first served"],
            "A problem encountered in multitasking when a process is perpetually denied necessary resources is called?": ["Deadlock", "Starvation", "Inversion", "Aging"]
        ],
        correctAnswers: [
            "Which one of the following is the deadlock avoidance algorithm?": "banker’s algorithm",
            "A problem encountered in multitasking when a process is perpetually denied necessary resources is called?": "Starvation"
        ]
    ),
    
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
    @State private var lifeLines=["50/50":true,"Skip Question":true]
    @State private var remainingAnswers:[String]?=nil
    @State private var showQuestion=false
    @State private var showOptions=false
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
                        .foregroundColor(timeRemaining < 5 ? .red : .purple)
                        .animation(.easeInOut, value: timeRemaining)
                        .padding()
                    
                    Spacer()
                    
                    Text("\(Int(adjustedScore))/\(topic.questions.count)")
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                let question = Array(topic.questions.keys)[questionIndex]
                let answers = remainingAnswers ?? topic.questions[question]!
                
                
                HStack{
                    Spacer()
                    
                        Button(action:{
                            skipQuestions()
                        }){
                            Text("Skip")
                                .font(.headline)
                                .padding()
                        }
                        .foregroundColor(.white)
                        .background(lifeLines["Skip Question"] == true ? Color.yellow.opacity(0.7) : Color.gray)
                        .cornerRadius(10)
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 10)
                        .disabled(lifeLines["Skip Question"] == false)
                    
                        Button(action:{
                            use5050(for: question)
                        })
                        {
                            Text("50/50")
                                .font(.headline)
                                .padding()
                        }
                        .foregroundColor(.white)
                        .background(lifeLines["50/50"] == true ? Color.yellow.opacity(0.7) : Color.gray)
                        .cornerRadius(10)
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 10)
                        .disabled(lifeLines["50/50"] == false)
                }
        
                    Text(question)
                        .font(.title3)
                        .padding()
                        .multilineTextAlignment(.center)
                        .opacity(showQuestion ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(showQuestion ? 0 : -90),
                            axis: (x: 0, y: 1, z: 0)
                    )
                        .animation(.easeInOut(duration: 0.5), value: showQuestion)

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
                        .rotation3DEffect(
                            .degrees(showOptions ? 0 : -90),
                            axis:(x:0,y:1,z:0)
                        )
                        .opacity(showOptions ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value:showOptions)
                        .disabled(isAnswered)
                        .onAppear{
                            animateQuestionsAndOptions()
                        }
                    }
                
                if hintAvailable && !hintUsed {
                    Button(action: {
                        hintUsed = true
                        hintText = "Here's a hint: \(getHint(for: question))"
                        adjustedScore = max(adjustedScore - 1, 0)
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
                animateQuestionsAndOptions()
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
            return colorScheme == .dark ? Color.purple : .white
        }
        if selectedAnswer == option {
            return isAnswerCorrect == true ? Color.green : Color.red
        } else {
            return colorScheme == .dark ? Color.purple : .white
        }
    }
    
    func nextQuestion() {
        if questionIndex + 1 >= topic.questions.count {
            stopTimer()
            finalScore = Int(adjustedScore)
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
            remainingAnswers=nil
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
    
    func skipQuestions() {
        if lifeLines["Skip Question"]==true{
            nextQuestion()
            lifeLines["Skip Question"]=false
        }
    }
    
    func use5050(for question:String) {
        if let correctAnswer = topic.correctAnswers[question], lifeLines["50/50"]==true{
            var incorrectAnswers=topic.questions[question]!.filter {$0 != correctAnswer}
            incorrectAnswers.shuffle()
            let eliminatedAnswers=incorrectAnswers.prefix(2)
            remainingAnswers=topic.questions[question]!.filter {!eliminatedAnswers.contains($0)}
            lifeLines["50/50"]=false
        }
    }
    
    func animateQuestionsAndOptions(){
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
            showQuestion=true
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+1.5){
            showOptions=true
        }
    }
}


struct EndPageView: View {
    @Binding var currentView: String?
    let score: Int
    let userName:String
    @State private var isUserNameEntered:Bool=false
    @Binding var selectedTopic: Topic?
    @Binding var leaderboard:[(name:String,topics:[(topic:String,score:Int)])]
    
    
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
                
                Button("View Leaderboard", systemImage: "list.number"){
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
        guard let topic=selectedTopic else{
            return
        }
        if let userIndex=leaderboard.firstIndex(where: {$0.name == userName}){
            if let topicIndex=leaderboard[userIndex].topics.firstIndex(where: {$0.topic == topic.name}){
                leaderboard[userIndex].topics[topicIndex].score=score
            }
            else{
                leaderboard[userIndex].topics.append((topic: topic.name, score:score))
            }
        }
        else{
            leaderboard.append((name: userName, topics:[(topic:topic.name, score:score)]))
        }
    }
}

struct LeaderboardView: View {
    @Binding var currentView: String?
    let leaderboard: [(name: String, topics:[(topic:String,score:Int)])]
    let totalQuizzes: Int
    @State private var selectedUser: UserDetail?
    @State private var isPopoverPresented: Bool = false

    var body: some View {
        VStack {
            Text("Leaderboard")
                .font(.largeTitle)
                .padding()

            List{
                ForEach(leaderboard, id:\.name){
                    entry in
                    Button{
                        let quizzes=entry.topics.map{
                            QuizDetail(topic:$0.topic, score:$0.score)
                        }
                        selectedUser=UserDetail(name:entry.name,quizzes:quizzes)
                        isPopoverPresented=true
                    }
                label: {
                    HStack{
                        Text(entry.name)
                            .font(.headline)
                        Spacer()
                        Text("\(entry.topics.count)/\(totalQuizzes)")
                            .font(.subheadline)
                    }
                    }
                }
            }
            .frame(minHeight: 400)
            .popover(isPresented: $isPopoverPresented) {
                if let user=selectedUser{
                    UserDetailView(user: user)
                }
            }
            Button("HomePage"){
                currentView="home"
            }
            .font(.headline)
            .padding()
            .background(.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

struct UserDetail: Identifiable {
    let id=UUID()
    let name:String
    let quizzes:[QuizDetail]
}

struct QuizDetail: Identifiable {
    let id=UUID()
    let topic:String
    let score:Int
}

struct UserDetailView: View {
    var user:UserDetail
    var body: some View {
        VStack{
            Text("\(user.name)'s Quiz Details")
                .font(.largeTitle)
                .padding()
            
            List(user.quizzes, id:\.id){
                quiz in
                HStack{
                    Text("Topic: \(quiz.topic)")
                        .font(.headline)
                    Spacer()
                    Text("Score: \(quiz.score)")
                        .font(.subheadline)
                }
            }
            .frame(minHeight: 200)
        }
    }
}



#Preview {
    ContentView()
}

//a task within a given process

