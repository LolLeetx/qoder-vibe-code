import SwiftUI

struct TasksView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var creatureVM: CreatureViewModel
    @State private var showAddTask = false
    @State private var showCompleted = false

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // XP Progress Section
                        xpSection

                        // Pending tasks
                        if taskVM.pendingTasks.isEmpty {
                            emptyState
                        } else {
                            taskListSection
                        }

                        // Completed toggle
                        if taskVM.completedCount > 0 {
                            completedSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "TASKS", color: PixelColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(PixelColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
                    .environmentObject(taskVM)
            }
            .overlay {
                if taskVM.showXPPopup, let gain = taskVM.lastXPGain {
                    XPPopupView(category: gain.category, amount: gain.amount, events: taskVM.latestEvents) {
                        taskVM.showXPPopup = false
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .animation(.spring(response: 0.3), value: taskVM.showXPPopup)
        }
    }

    private var xpSection: some View {
        PixelCard {
            VStack(spacing: 8) {
                HStack {
                    PixelText(text: "CATEGORY XP", size: 12, color: .gray)
                    Spacer()
                }
                ForEach(TaskCategory.allCases) { category in
                    XPProgressBar(
                        currentXP: taskVM.xpManager.xp(for: category),
                        nextMilestone: taskVM.xpManager.nextMilestone(for: category),
                        category: category
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            PixelText(text: "No tasks yet!", size: 16, color: .gray)
            PixelText(text: "Add tasks to earn XP", size: 12, color: .gray.opacity(0.7))
            PixelButton(title: "+ ADD TASK", color: PixelColors.accent) {
                showAddTask = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var taskListSection: some View {
        VStack(spacing: 8) {
            HStack {
                PixelText(text: "TO DO", size: 12, color: .gray)
                Spacer()
                PixelText(text: "\(taskVM.pendingTasks.count) tasks", size: 10, color: .gray.opacity(0.7))
            }

            ForEach(taskVM.pendingTasks) { task in
                TaskRowView(task: task)
                    .environmentObject(taskVM)
            }
        }
    }

    private var completedSection: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation { showCompleted.toggle() } }) {
                HStack {
                    PixelText(text: "COMPLETED", size: 12, color: .gray)
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Spacer()
                    PixelText(text: "\(taskVM.completedCount)", size: 10, color: PixelColors.success)
                }
            }

            if showCompleted {
                ForEach(taskVM.tasks.filter(\.isCompleted)) { task in
                    TaskRowView(task: task)
                        .environmentObject(taskVM)
                        .opacity(0.6)
                }
            }
        }
    }
}

// MARK: - XP Popup

struct XPPopupView: View {
    let category: TaskCategory
    let amount: Int
    let events: [XPEvent]
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                PixelText(text: "+\(amount) XP", size: 28, color: PixelColors.gold)

                TypeBadge(category: category)

                ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                    eventRow(event)
                }

                PixelButton(title: "OK", color: PixelColors.accent) {
                    onDismiss()
                }
            }
            .padding(24)
            .background(PixelColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PixelColors.gold, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(40)
        }
    }

    @ViewBuilder
    private func eventRow(_ event: XPEvent) -> some View {
        switch event {
        case .creatureUnlocked(let cat):
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(PixelColors.gold)
                PixelText(text: "\(cat.creatureNames[0]) joined you!", size: 13, color: PixelColors.gold)
            }
        case .creatureEvolved(let cat, let stage):
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(PixelColors.gold)
                PixelText(text: "\(cat.creatureNames[min(stage-1, 2)]) evolved!", size: 13, color: PixelColors.gold)
            }
        case .xpGained:
            EmptyView()
        }
    }
}
