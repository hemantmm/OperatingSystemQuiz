//
//  ContentView.swift
//  OperatingSystemQuiz
//
//  Created by Hemant Mehta on 20/01/25.
//

import SwiftUI
import ConfettiSwiftUI
import AVKit
import PhotosUI

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
    @State private var currentView:String? = "home"
    @State private var finalScore:Int = 0
    @State private var selectedTopic:Topic?=nil
    @State private var userName:String=""
    @State private var userInitial:String=""
    @State private var leaderboard:[(name:String,topics:[(topic:String,score:Int)])]=[]
    let totalQuizzes:Int=10
    @State private var earnedBadges:[String] = []
    @State private var profileImage: NSImage? = nil
    
    var body: some View {
        VStack {
             if currentView=="home"{
                HomeView(currentView: $currentView, selectedTopic: $selectedTopic, leaderboard: $leaderboard, userInitial: $userInitial, userName:$userName,profileImage: $profileImage)
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
                EndPageView(currentView: $currentView, earnedBadges:$earnedBadges, score: finalScore, userName: userName, selectedTopic: $selectedTopic, leaderboard: $leaderboard)
            }
            else if currentView=="leaderboard"{
                LeaderboardView(currentView: $currentView, leaderboard: leaderboard, totalQuizzes: totalQuizzes)
            }
            else if currentView=="badges"{
                BadgesView(currentView: $currentView,earnedBadges:$earnedBadges,userName:userName)
            }
            else if currentView=="profile"{
                ProfileView(currentView: $currentView, userName: userName, leaderboard: leaderboard,profileImage: $profileImage, earnedBadges: $earnedBadges)
            }
        }
        .padding()
    }
}

struct ProfileView: View {
    @Binding var currentView: String?
    var userName: String
    @State private var email: String = ""
    var leaderboard: [(name: String, topics: [(topic: String, score: Int)])]
    @Binding var profileImage: NSImage?
    @Binding var earnedBadges: [String]
    @State private var streakCount: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .shadow(radius: 5)
                
                if let image = profileImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
            }
            .onTapGesture {
                selectProfileImage()
            }
            
            VStack(spacing: 10) {
                HStack {
                    StatView(title: "Quizzes Attempted", value: "\(totalQuizzesAttempted)")
                    Spacer()
                    StatView(title: "Badges Earned", value: "\(earnedBadges.count)")
                }
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                currentView = "home"
            }) {
                Text("Back to Home")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            loadProfileImage()
        }
    }

    private func loadProfileImage() {
        let key = "profileImagePath_\(userName)"
        if let path = UserDefaults.standard.string(forKey: key),
           let image = NSImage(contentsOfFile: path) {
            profileImage = image
        } else {
            profileImage = nil
        }
    }

    private func saveProfileImagePath(_ url: URL) {
        let key = "profileImagePath_\(userName)"
        UserDefaults.standard.set(url.path, forKey: key)
    }

    private func selectProfileImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                profileImage = image
                saveProfileImagePath(url)
            }
        }
    }

    private var totalQuizzesAttempted: Int {
        return leaderboard.first(where: { $0.name == userName })?.topics.count ?? 0
    }
}

struct StatView: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
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
    @Binding var profileImage:NSImage?
    @State private var earnedBadges: [String] = UserDefaults.standard.array(forKey: "earnedBadges") as? [String] ?? []


    @AppStorage("lastChallengeDate") private var lastChallengeDate: Date?

    var body: some View {
        
        
        HStack {
            Spacer()
            Button(action: {
                showDropdown.toggle()
            }) {
                if let image=profileImage{
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white,lineWidth: 3))
                }
                else{
                    Circle()
                        .fill(.black)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(userInitial)
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.purple)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .popover(isPresented: $showDropdown) {
                VStack {
                    Button("Profile", systemImage: "person.crop.circle") {
                        currentView = "profile"
                    }
                    .font(.headline)
                    .padding()
                    .background(.white)
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                    .buttonStyle(PlainButtonStyle())
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

                Button("Daily Question Mode", systemImage:"questionmark.circle") {
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
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding()
                }

                Button("View Leaderboard",systemImage: "list.number") {
                    currentView = "leaderboard"
                }
                .font(.headline)
                .padding()
                .foregroundColor(.white)
                .background(Color.yellow.opacity(0.7))
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                .fontWeight(.bold)
                
                Button("Badges", systemImage: "trophy.circle") {
                    currentView = "badges"
                }
                .font(.headline)
                .padding()
                .background(.white)
                .foregroundColor(.purple)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
            }
            .padding()
            .onAppear{
                loadProfileImage()
            }
        }
        .background(.purple)
        .cornerRadius(10)
    }
    
    private func loadProfileImage() {
            let key = "profileImagePath_\(userName)"
            if let path = UserDefaults.standard.string(forKey: key),
               let image = NSImage(contentsOfFile: path) {
                profileImage = image
            } else {
                profileImage = nil
            }
        }

    func updateRemainingTime() {
        let userKey="lastChallengeDate_\(userName)"
        guard var lastDate:Date = UserDefaults.standard.object(forKey: userKey) as? Date else {
            remainingTime=0
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

struct DailyQuestionModeView: View {
    @Binding var currentView: String?
    @Binding var userName: String
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var isAnswered = false
    @State private var selectedAnswer: String? = nil
    @State private var isAnswerCorrect: Bool? = nil
    @State private var confettiCounter: Int = 0
    @State private var timeRemaining = 20

    
    @AppStorage("lastChallengeDate") private var lastChallengeDate: Date?

    let challengeQuestions: [String: [String]] = [
        "What is the main function of the operating system kernel?": ["Manage hardware resources", "Run applications", "Provide internet access", "Store files"],
        "What scheduling algorithm gives equal time to all processes?": ["Round-robin", "First Come First Serve", "Shortest Job First", "Priority Scheduling"],
        "Which one of the following is not a real time operating system?": ["VxWorks", "QNX", "RTLinux", "Palm OS"]
    ]
    
    let correctAnswers: [String: String] = [
        "What is the main function of the operating system kernel?": "Manage hardware resources",
        "What scheduling algorithm gives equal time to all processes?": "Round-robin",
        "Which one of the following is not a real time operating system?": "Palm OS"
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
                    .buttonStyle(PlainButtonStyle())
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
            let userKey="lastChallengeDate_\(userName)"
            UserDefaults.standard.set(Date(), forKey: userKey)
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
        name: "Thread",
        description: "A task within a given process.",
        questions: [
            "If one thread opens a file with read privileges then?": ["other threads in the another process can also read from that file", "other threads in the same process can also read from that file", "any other thread can not read from that file", "all of the mentioned"],
            "Which one of the following is not a valid state of a thread?": ["running", "parsing", "ready", "blocked"],
            "A process can be?":["single threaded","multithreaded","both single threaded and multithreaded","none of the mentioned"]
        ],
        correctAnswers: [
            "If one thread opens a file with read privileges then?": "other threads in the same process can also read from that file",
            "Which one of the following is not a valid state of a thread?": "parsing",
            "A process can be?": "both single threaded and multithreaded"
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
    Topic(
        name: "Virtual Memory",
        description: "A temporary memory. It is a memory which is larger than the real memory. It is an address line memory",
        questions: [
            "Size of virtual memory depends on?": ["Address line", "Data Base", "Disc space", "All the above"],
            "The instruction being executed, must be in?": ["physical memory", "logical memory", "physical & logical memory", "none of the mentioned"],
            "Virtual memory is normally implemented by?": ["demand paging","buses","virtualization","all of the mentioned"]
        ],
        correctAnswers: [
            "Size of virtual memory depends on?": "Address line",
            "The instruction being executed, must be in?": "physical memory",
            "Virtual memory is normally implemented by?": "demand paging"
        ]
    ),
    Topic(
        name: "Cache",
        description: "A high-speed memory component used to store frequently accessed data and instructions. Caches are placed between the CPU and main memory (RAM). It has only 1 sign bit.",
        questions: [
            "Whenever the data is found in the cache memory it is called as?": ["HIT", "MISS", "FOUND", "ERROR"],
            "When the data at a location in cache is different from the data located in the main memory, the cache is called?": ["Unique", "Inconsistent", "Variable", "Fault"],
            "The number of sign bits in a 32-bit IEEE format is?": ["1","11","9","23"]
        ],
        correctAnswers: [
            "Whenever the data is found in the cache memory it is called as?": "HIT",
            "When the data at a location in cache is different from the data located in the main memory, the cache is called?": "Inconsistent",
            "The number of sign bits in a 32-bit IEEE format is?": "1"
        ]
    ),
    Topic(
        name: "Semaphore",
        description: "Semaphores are synchronisation primitives used to manage concurrent processes by controlling access to shared resources. A variable that controls access to shared resource.They are essential for preventing race conditions.",
        questions: [
            "Semaphore is a/an _______ to solve the critical section problem?": ["hardware for a system", "special program for a system", "integer variable", "none of the mentioned"],
            "The signal operation of the semaphore basically works on the basic _______ system call?": ["continue()", "wakeup()", "getup()", "start()"]
        ],
        correctAnswers: [
            "Semaphore is a/an _______ to solve the critical section problem?": "integer variable",
            "The signal operation of the semaphore basically works on the basic _______ system call?": "wakeup()"
        ]
    ),
    Topic(
        name: "RAID",
        description: "RAID (Redundant Array of Independent Disks) is like having backup copies of your important files at different places of several hard drives.",
        questions: [
            "In RAID level 4, one block read, accesses?": ["only one disk", "all disks simultaneously", "all disks sequentially", "none of the mentioned"],
            "The overall I/O rate in RAID level 4 is?": ["low", "very low", "high", "none of the mentioned"],
            "If a disk fails in RAID level ___________ rebuilding lost data is easiest?": ["1","2","3","4"]
        ],
        correctAnswers: [
            "In RAID level 4, one block read, accesses?": "only one disk",
            "The overall I/O rate in RAID level 4 is?": "high",
            "If a disk fails in RAID level ___________ rebuilding lost data is easiest?": "1"
        ]
    ),
    Topic(
        name: "Producer-Consumer",
        description: "The producer-consumer synchronisation is used to manage the communication between two software processors: producers and consumers. The producer generates data and sends it to the consumer, which processes the data. There are n buffers.",
        questions: [
            "The bounded buffer problem is also known as?": ["Readers – Writers problem", "Dining – Philosophers problem", "Producer – Consumer problem", "none of the mentioned"],
            "In the bounded buffer problem?": ["there is only one buffer", "there are n buffers", "there are infinite buffers", "the buffer size is bounded"],
            "The dining – philosophers problem will occur in case of?": ["5 philosophers and 5 chopsticks","4 philosophers and 5 chopsticks","3 philosophers and 5 chopsticks","6 philosophers and 5 chopsticks"]
        ],
        correctAnswers: [
            "The bounded buffer problem is also known as?": "Producer – Consumer problem",
            "In the bounded buffer problem?": "there are n buffers",
            "The dining – philosophers problem will occur in case of?": "5 philosophers and 5 chopsticks"
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
            }
            .padding()
            .onAppear {
                startTimer()
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
    @Binding var earnedBadges: [String]
    let score: Int
    let userName: String
    @Binding var selectedTopic: Topic?
    @Binding var leaderboard: [(name: String, topics: [(topic: String, score: Int)])]

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
            
            if score == selectedTopic?.questions.count, let topicName = selectedTopic?.name {
                if earnedBadges.contains(topicName) {
                    Text("✅ You already earned the badge for \(topicName)!")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                } else {
                    Text("🏅 You've earned a new badge for \(topicName)! 🎖️")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                }
            }

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
                    saveScoreToLeaderboard()
                    currentView = "home"
                }
                .font(.headline)
                .padding()
                .background(Color.mint)
                .foregroundColor(.black)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
                Button("View Leaderboard", systemImage: "list.number") {
                    saveScoreToLeaderboard()
                    currentView = "leaderboard"
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
        .onAppear {
            loadBadges(for: userName)
        }
    }
    private func saveScoreToLeaderboard() {
        guard let topic = selectedTopic else { return }

        DispatchQueue.main.async {
            if score == topic.questions.count { // Check for 100% score
                if !earnedBadges.contains(topic.name) {
                    earnedBadges.append(topic.name)
                    UserDefaults.standard.set(earnedBadges, forKey: "earnedBadges") // Save globally
                }
            }

            if let userIndex = leaderboard.firstIndex(where: { $0.name == userName }) {
                if let topicIndex = leaderboard[userIndex].topics.firstIndex(where: { $0.topic == topic.name }) {
                    leaderboard[userIndex].topics[topicIndex].score = score
                } else {
                    leaderboard[userIndex].topics.append((topic: topic.name, score: score))
                }
            } else {
                leaderboard.append((name: userName, topics: [(topic: topic.name, score: score)]))
            }

            leaderboard.sort {
                $0.topics.reduce(0) { $0 + $1.score } > $1.topics.reduce(0) { $0 + $1.score }
            }
        }
    }

    private func loadBadges(for user: String) {
        let key = "earnedBadges_\(user)"
        if let savedBadges = UserDefaults.standard.array(forKey: key) as? [String] {
            earnedBadges = savedBadges
        } else {
            earnedBadges = []
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
            List {
                ForEach(leaderboard.sorted(by: {
                    $0.topics.reduce(0) { $0 + $1.score } > $1.topics.reduce(0) { $0 + $1.score }
                }), id: \.name) { entry in
                    Button {
                        let quizzes = entry.topics.map {
                            QuizDetail(topic: $0.topic, score: $0.score)
                        }
                        selectedUser = UserDetail(name: entry.name, quizzes: quizzes)
                        isPopoverPresented = true
                    } label: {
                        HStack {
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

struct BadgesView: View {
    @Binding var currentView: String?
    @Binding var earnedBadges: [String]
    let userName: String

    var body: some View {
        VStack {
            Text("Your Achievements")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
                .foregroundColor(.indigo)

            if earnedBadges.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "star.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray.opacity(0.6))

                    Text("No badges earned yet!")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.6))

                    Text("Start taking quizzes and earn your first badge!")
                        .font(.body)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                        ForEach(earnedBadges, id: \.self) { badge in
                            VStack {
                                Image(systemName: "medal.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.yellow)
                                    .shadow(radius: 5)

                                Text(badge)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .padding(.top, 5)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(radius: 5)
                            )
                            .frame(width: 120, height: 140)
                        }
                    }
                    .padding()
                }
            }

            Button(action: {
                currentView = "home"
            }) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Home Page")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            .padding(.horizontal, 20)
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 20)
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [.purple, .white]), startPoint: .top, endPoint: .bottom))
    }
}



#Preview {
    ContentView()
}
