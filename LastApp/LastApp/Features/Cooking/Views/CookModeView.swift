// LastApp/LastApp/Features/Cooking/Views/CookModeView.swift
import SwiftUI

struct CookModeView: View {
    var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    private var sortedSteps: [RecipeStep] {
        recipe.steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var currentStep: RecipeStep? {
        sortedSteps.indices.contains(currentIndex) ? sortedSteps[currentIndex] : nil
    }

    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == sortedSteps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar
            stepContent
            navButtons
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.appAccent)
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Subviews

    private var header: some View {
        Text("Step \(currentIndex + 1) of \(sortedSteps.count)")
            .font(.system(.subheadline, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appAccent)
                    .frame(
                        width: sortedSteps.isEmpty
                            ? 0
                            : geo.size.width * CGFloat(currentIndex + 1) / CGFloat(sortedSteps.count)
                    )
            }
        }
        .frame(height: 4)
        .padding(.horizontal, AppTheme.padding)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stepContent: some View {
        if recipe.steps.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                Text("No steps added")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 24) {
                Text("Step \(currentIndex + 1)")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .textCase(.uppercase)
                    .tracking(1.5)

                if let step = currentStep {
                    Text(step.instruction)
                        .font(.system(.title3, weight: .regular))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, AppTheme.padding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var navButtons: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3)) { currentIndex -= 1 }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Prev")
                }
                .font(.system(.body, weight: .medium))
                .foregroundStyle(isFirst ? Color.secondary : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Color.secondary.opacity(isFirst ? 0.08 : 0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .disabled(isFirst)
            .buttonStyle(.plain)

            Button {
                if isLast {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3)) { currentIndex += 1 }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLast ? "Finish" : "Next")
                    if !isLast { Image(systemName: "chevron.right") }
                }
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.padding)
    }
}
