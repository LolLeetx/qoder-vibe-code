import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var taskVM: TaskViewModel

    var body: some View {
        PixelCard(borderColor: task.category.color.opacity(0.4)) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: {
                    if !task.isCompleted {
                        withAnimation(.spring(response: 0.3)) {
                            taskVM.completeTask(task)
                        }
                        let feedback = UINotificationFeedbackGenerator()
                        feedback.notificationOccurred(.success)
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? PixelColors.success : .gray)
                }

                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .strikethrough(task.isCompleted, color: .gray)

                    HStack(spacing: 8) {
                        TypeBadge(category: task.category, small: true)
                        difficultyBadge
                    }
                }

                Spacer()

                // XP reward
                if !task.isCompleted {
                    PixelText(text: "+\(task.difficulty.xpReward)", size: 12, color: PixelColors.gold)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation { taskVM.deleteTask(task) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var difficultyBadge: some View {
        Text(task.difficulty.displayName)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(difficultyColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(difficultyColor.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var difficultyColor: Color {
        switch task.difficulty {
        case .easy: return PixelColors.success
        case .medium: return PixelColors.gold
        case .hard: return PixelColors.danger
        }
    }
}
