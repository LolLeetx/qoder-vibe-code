import Foundation
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var showXPPopup: Bool = false
    @Published var lastXPGain: (category: TaskCategory, amount: Int)?
    @Published var latestEvents: [XPEvent] = []

    let xpManager = XPManager.shared
    private var storageKey = "tasks"

    init() {}

    func setUser(_ userId: String) {
        storageKey = "tasks_\(userId)"
        loadTasks()
    }

    func clearData() {
        tasks = []
    }

    // MARK: - CRUD

    func addTask(title: String, category: TaskCategory, difficulty: TaskDifficulty) {
        let task = TaskItem(title: title, category: category, difficulty: difficulty)
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func completeTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard !tasks[index].isCompleted else { return }

        tasks[index].isCompleted = true
        let xp = task.difficulty.xpReward

        let events = xpManager.awardXP(amount: xp, to: task.category)
        lastXPGain = (task.category, xp)
        latestEvents = events
        showXPPopup = true

        saveTasks()
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func incompleteTasks(for category: TaskCategory) -> [TaskItem] {
        tasks.filter { $0.category == category && !$0.isCompleted }
    }

    func completedTasks(for category: TaskCategory) -> [TaskItem] {
        tasks.filter { $0.category == category && $0.isCompleted }
    }

    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    // MARK: - Persistence

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([TaskItem].self, from: data) else { return }
        tasks = saved
    }
}
