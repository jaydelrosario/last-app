import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @GestureState private var openDrag: CGFloat = 0
    @GestureState private var closeDrag: CGFloat = 0

    private let sidebarWidth: CGFloat = AppTheme.sidebarWidth

    private var offset: CGFloat {
        if appState.isSidebarOpen {
            return min(0, closeDrag)
        } else {
            return max(-sidebarWidth, -sidebarWidth + max(0, openDrag))
        }
    }

    private var progress: CGFloat {
        (sidebarWidth + offset) / sidebarWidth
    }

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Dimming overlay — tap or swipe left to close
            Color.black.opacity(0.35 * progress)
                .ignoresSafeArea()
                .allowsHitTesting(progress > 0.01)
                .onTapGesture { appState.isSidebarOpen = false }

            // Sidebar — drag left on it to close
            SidebarView()
                .ignoresSafeArea()
                .offset(x: offset)
                .shadow(color: .black.opacity(0.2 * progress), radius: 20, x: 8, y: 0)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .updating($closeDrag) { value, state, _ in
                            guard value.translation.width < 0 else { return }
                            state = value.translation.width
                        }
                        .onEnded { value in
                            if value.translation.width < -(sidebarWidth * 0.3) ||
                               value.predictedEndTranslation.width < -(sidebarWidth * 0.5) {
                                appState.isSidebarOpen = false
                            }
                        }
                )

            // Left-edge hot zone — drag right from here to open
            if !appState.isSidebarOpen {
                Color.clear
                    .frame(width: 30)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .updating($openDrag) { value, state, _ in
                                guard value.translation.width > 0 else { return }
                                state = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width > sidebarWidth * 0.3 ||
                                   value.predictedEndTranslation.width > sidebarWidth * 0.5 {
                                    appState.isSidebarOpen = true
                                }
                            }
                    )
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
