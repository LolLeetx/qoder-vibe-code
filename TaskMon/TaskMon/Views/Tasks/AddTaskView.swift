import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var category: TaskCategory = .work
    @State private var difficulty: TaskDifficulty = .medium

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            PixelText(text: "TASK NAME", size: 12, color: .gray)
                            TextField("", text: $title, prompt: Text("What do you need to do?").foregroundColor(.gray.opacity(0.5)))
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(PixelColors.cardBorder, lineWidth: 2)
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            PixelText(text: "CATEGORY", size: 12, color: .gray)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                                ForEach(TaskCategory.allCases) { cat in
                                    Button(action: { category = cat }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12))
                                            Text(cat.displayName)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        }
                                        .foregroundColor(category == cat ? .black : cat.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(category == cat ? cat.color : cat.color.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(cat.color, lineWidth: category == cat ? 0 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }

                        // Difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            PixelText(text: "DIFFICULTY", size: 12, color: .gray)
                            HStack(spacing: 8) {
                                ForEach(TaskDifficulty.allCases) { diff in
                                    Button(action: { difficulty = diff }) {
                                        VStack(spacing: 4) {
                                            Text(diff.displayName)
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            Text("+\(diff.xpReward) XP")
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundColor(difficulty == diff ? .black.opacity(0.7) : PixelColors.gold)
                                        }
                                        .foregroundColor(difficulty == diff ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(difficulty == diff ? diffColor(diff) : diffColor(diff).opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(diffColor(diff), lineWidth: difficulty == diff ? 0 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }

                        // Preview
                        VStack(alignment: .leading, spacing: 8) {
                            PixelText(text: "PREVIEW", size: 12, color: .gray)
                            PixelCard(borderColor: category.color.opacity(0.5)) {
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                    VStack(alignment: .leading, spacing: 4) {
                                        PixelText(text: title.isEmpty ? "Task name" : title, size: 14, color: title.isEmpty ? .gray : .white)
                                        HStack {
                                            TypeBadge(category: category, small: true)
                                            Text(difficulty.displayName)
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(diffColor(difficulty))
                                        }
                                    }
                                    Spacer()
                                    PixelText(text: "+\(difficulty.xpReward)", size: 12, color: PixelColors.gold)
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "NEW TASK", color: PixelColors.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTask) {
                        PixelText(text: "ADD", size: 14, color: title.isEmpty ? .gray : PixelColors.accent)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        taskVM.addTask(title: title.trimmingCharacters(in: .whitespaces), category: category, difficulty: difficulty)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        dismiss()
    }

    private func diffColor(_ diff: TaskDifficulty) -> Color {
        switch diff {
        case .easy: return PixelColors.success
        case .medium: return PixelColors.gold
        case .hard: return PixelColors.danger
        }
    }
}
