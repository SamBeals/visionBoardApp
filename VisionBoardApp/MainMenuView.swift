import SwiftUI

struct MainMenuView: View {
    let userId: String   // ← add this stored property

    init(userId: String) {
        self.userId = userId
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Welcome to Vision Board")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                // 📸 Habit Tracker Button
                // In MainMenuView
                NavigationLink(destination: HabitsHome(userId: userId)) {
                    MenuButtonView(title: "Habit Tracker", emoji: "📸")
                }

                // ✅ To-Do List Button
                NavigationLink(destination: ToDoListView()) {
                    MenuButtonView(title: "To-Do List", emoji: "✅")
                }

                // 🌄 Long-Term Aspirations Button
                NavigationLink(destination: AspirationsView()) {
                    MenuButtonView(title: "Long-Term Aspirations", emoji: "🌄")
                }

                // 💬 Affirmations Button
                NavigationLink(destination: AffirmationsView()) {
                    MenuButtonView(title: "Affirmations", emoji: "💬")
                }

                Spacer()
            }
            .padding()
        }
    }
}

// 🧱 A simple reusable button-style card view
struct MenuButtonView: View {
    let title: String
    let emoji: String

    var body: some View {
        HStack {
            Text(emoji)
                .font(.largeTitle)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    MainMenuView(userId: "preview-uid")
}
