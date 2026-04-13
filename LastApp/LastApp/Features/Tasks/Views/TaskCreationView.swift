// LastApp/Features/Tasks/Views/TaskCreationView.swift
import SwiftUI
import SwiftData

struct TaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var customLists: [TaskList]

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date? = nil
    @State private var priority: Priority = .p4
    @State private var selectedList: TaskList? = nil
    @State private var isExpanded = false
    @State private var showingDatePicker = false
    @FocusState private var titleFocused: Bool

    init(initialDueDate: Date? = nil) {
        _dueDate = State(initialValue: initialDueDate)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Task name", text: $title, axis: .vertical)
                    .font(.system(.title3, weight: .medium))
                    .focused($titleFocused)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .submitLabel(.done)
                    .onSubmit { saveIfValid() }

                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        dateChip("Today", date: .now)
                        dateChip("Tomorrow", date: .tomorrow)
                        dateChip("Next Week", date: .nextWeek)
                        customDateChip

                        Divider().frame(height: 20)

                        ForEach(Priority.allCases.filter { $0 != .p4 }, id: \.self) { p in
                            priorityChip(p)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.vertical, 10)
                }

                if isExpanded {
                    Divider()
                    expandedFields
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { saveIfValid() }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.appAccent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { saveIfValid() }
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .presentationDetents(isExpanded ? [.large] : [.height(260)])
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
    }

    private var expandedFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Notes", text: $notes, axis: .vertical)
                .font(.system(.body))
                .foregroundStyle(.secondary)
                .padding(AppTheme.padding)

            if !customLists.isEmpty {
                Divider()
                Picker("List", selection: $selectedList) {
                    Text("Inbox").tag(nil as TaskList?)
                    ForEach(customLists) { list in
                        Label(list.name, systemImage: list.icon).tag(list as TaskList?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, AppTheme.padding)
                .padding(.vertical, 10)
            }
        }
    }

    private var customDateChip: some View {
        let isCustom = dueDate.map { d in
            !Calendar.current.isDateInToday(d) &&
            !Calendar.current.isDate(d, inSameDayAs: .tomorrow) &&
            !Calendar.current.isDate(d, inSameDayAs: .nextWeek)
        } ?? false

        return Button {
            showingDatePicker.toggle()
        } label: {
            Text(isCustom ? dueDate!.formatted(.dateTime.month(.abbreviated).day()) : "Pick date")
                .font(.system(.caption, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isCustom ? Color.appAccent : Color.secondary.opacity(0.15)))
                .foregroundStyle(isCustom ? .white : .primary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingDatePicker) {
            DatePicker("", selection: Binding(
                get: { dueDate ?? .now },
                set: { dueDate = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(.graphical)
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }

    private func dateChip(_ label: String, date: Date) -> some View {
        let isSelected = dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            dueDate = isSelected ? nil : date
        } label: {
            Text(label)
                .font(.system(.caption, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.appAccent : Color.secondary.opacity(0.15)))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func priorityChip(_ p: Priority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = isSelected ? .p4 : p
        } label: {
            ZStack {
                Circle()
                    .fill(Color.priorityColor(p))
                    .frame(width: 28, height: 28)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveIfValid() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { dismiss(); return }
        let task = TaskItem(title: trimmed, notes: notes, dueDate: dueDate, priority: priority, list: selectedList)
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    TaskCreationView()
        .modelContainer(for: [TaskItem.self, TaskList.self], inMemory: true)
}
