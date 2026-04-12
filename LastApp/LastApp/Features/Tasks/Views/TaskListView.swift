// LastApp/Features/Tasks/Views/TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @State private var showingCreation = false

    private var viewModel: TaskViewModel {
        TaskViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }

            Button {
                showingCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(.title2, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.appAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(AppTheme.padding)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreation) {
            TaskCreationView()
        }
    }

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(value: task) {
                    TaskRowView(task: task) {
                        withAnimation { viewModel.toggleComplete(task) }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                viewModel.delete(offsets.map { filteredTasks[$0] })
            }
            .onMove { from, to in
                var reordered = filteredTasks
                reordered.move(fromOffsets: from, toOffset: to)
                viewModel.updateSortOrder(reordered)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(emptyStateMessage)
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredTasks: [TaskItem] {
        let now = Date()
        switch appState.selectedDestination {
        case .inbox:
            return allTasks.filter { $0.list == nil && !$0.isCompleted }
        case .today:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 <= now.endOfDay } ?? false) }
        case .upcoming:
            return allTasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 > now.endOfDay } ?? false) }
        case .completed:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return allTasks.filter { $0.isCompleted && ($0.completedAt ?? Date.distantPast) >= thirtyDaysAgo }
        case .list(let id):
            return allTasks.filter { $0.list?.id == id && !$0.isCompleted }
        case .habits, .workout, .settings:
            return []
        }
    }

    private var navigationTitle: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .list(let id): allTasks.first { $0.list?.id == id }?.list?.name ?? "List"
        case .habits, .workout, .settings: ""
        }
    }

    private var emptyStateIcon: String {
        switch appState.selectedDestination {
        case .inbox: "tray"
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .completed: "checkmark.circle"
        default: "list.bullet"
        }
    }

    private var emptyStateMessage: String {
        switch appState.selectedDestination {
        case .inbox: "Inbox zero"
        case .today: "Nothing due today"
        case .upcoming: "Nothing coming up"
        case .completed: "No completed tasks"
        default: "No tasks"
        }
    }
}

