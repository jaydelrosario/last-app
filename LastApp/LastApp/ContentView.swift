import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appState.isSidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { appState.isSidebarOpen = false }
                    .transition(.opacity)
            }

            if appState.isSidebarOpen {
                SidebarView()
                    .ignoresSafeArea()
                    .transition(.move(edge: .leading))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 8, y: 0)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: appState.isSidebarOpen)
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            destinationView
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            appState.isSidebarOpen.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(.body, weight: .medium))
                        }
                        .tint(.primary)
                    }
                }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch appState.selectedDestination {
        case .inbox, .upcoming, .completed, .list:
            TaskListView()
        case .today:
            TodayView()
        case .habits:
            HabitListView()
        case .settings:
            SettingsView()
        }
    }
}


#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, TaskList.self, Habit.self, HabitLog.self, FeatureConfig.self, FeatureLink.self], inMemory: true)
}
