// LastApp/Features/Tasks/Views/TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @State private var showingCreation = false
    @State private var lastCompletedTask: TaskItem? = nil
    @State private var showToast = false
    @State private var toastId = UUID()

    private var viewModel: TaskViewModel {
        TaskViewModel(context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()
            Group {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }

            if showToast {
                completionToast
                    .padding(.bottom, 74)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
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
        .task(id: toastId) {
            guard showToast else { return }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.spring) { showToast = false }
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
                        if task.isCompleted {
                            lastCompletedTask = task
                            toastId = UUID()
                            withAnimation(.spring) { showToast = true }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
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
        .scrollContentBackground(.hidden)
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 52))
                .foregroundStyle(Color.appAccent.opacity(0.25))
            VStack(spacing: 6) {
                Text(emptyStateMessage)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(emptyStateSubtitle)
                    .font(.system(.subheadline))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            if showsAddButton {
                Button {
                    showingCreation = true
                } label: {
                    Text("Add Task")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.appAccent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completion Toast

    private var completionToast: some View {
        Button {
            if let task = lastCompletedTask {
                withAnimation { viewModel.toggleComplete(task) }
            }
            withAnimation(.spring) { showToast = false }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Undo")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                    Text("Completed")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.padding)
    }

    private var emptyStateSubtitle: String {
        switch appState.selectedDestination {
        case .inbox: "Tasks without a due date or list live here"
        case .today: "Tasks due today will appear here"
        case .upcoming: "Future due dates will appear here"
        case .completed: "Completed tasks from the last 30 days"
        default: "No tasks in this list yet"
        }
    }

    private var showsAddButton: Bool {
        switch appState.selectedDestination {
        case .inbox, .list: true
        default: false
        }
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
        case .habits, .workout, .cooking, .notes, .settings:
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
        case .habits, .workout, .cooking, .notes, .settings: ""
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

