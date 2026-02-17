import SwiftUI
import Charts

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var valueColor: Color = AppColors.textPrimary
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(value)
                .font(AppTypography.kpiSmall)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: AppSpacing.md)
    }
}

// MARK: - Large KPI Card

struct LargeKPICard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var valueColor: Color = AppColors.accentBlue
    var icon: String = "chart.bar.fill"

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(valueColor.opacity(0.7))

            Text(value)
                .font(AppTypography.kpiLarge)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.accentBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.top, AppSpacing.sm)
    }
}

// MARK: - Labeled Input Field

struct LabeledInputField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    var suffix: String? = nil
    var prefix: String? = nil
    var info: String? = nil
    var keyboardType: UIKeyboardType = .decimalPad
    /// When true, validates that the text is a valid positive number (for numeric fields).
    var validateNumeric: Bool = true

    private var hasError: Bool {
        guard validateNumeric, keyboardType == .decimalPad, !value.isEmpty else { return false }
        guard let number = Double(value) else { return true }
        return number < 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                if let info {
                    Text(info)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                if let prefix {
                    Text(prefix)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textTertiary)
                }
                TextField(placeholder, text: $value)
                    .keyboardType(keyboardType)
                    .font(AppTypography.body)
                    .foregroundColor(hasError ? AppColors.lossRed : AppColors.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                    .fill(AppColors.backgroundInput)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                            .stroke(hasError ? AppColors.lossRed.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
            )

            if hasError {
                Text("Enter a valid number")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.lossRed.opacity(0.8))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: hasError)
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppColors.textPrimary
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? AppTypography.body : AppTypography.caption)
                .foregroundColor(isBold ? AppColors.textPrimary : AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(isBold ? AppTypography.title : AppTypography.metricValue)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let insight: MarketingInsight

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: insight.severity.iconName)
                .font(.system(size: 16))
                .foregroundColor(iconColor)

            Text(insight.message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                .fill(iconColor.opacity(0.08))
        )
    }

    private var iconColor: Color {
        switch insight.severity {
        case .critical: return AppColors.lossRed
        case .warning: return AppColors.warningYellow
        case .info: return AppColors.accentBlue
        case .positive: return AppColors.profitGreen
        }
    }
}

// MARK: - Animated Number

struct AnimatedNumberView: View {
    let value: Double
    let format: (Double) -> String
    var color: Color = AppColors.textPrimary
    var font: Font = AppTypography.kpiMedium

    @State private var displayedValue: Double = 0

    var body: some View {
        Text(format(displayedValue))
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText(value: displayedValue))
            .onChange(of: value) { _, newValue in
                withAnimation(.easeInOut(duration: 0.4)) {
                    displayedValue = newValue
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    displayedValue = value
                }
            }
    }
}

// MARK: - Funnel Bar

struct FunnelBar: View {
    let stage: FunnelStage
    let maxCount: Double
    let currency: String
    @State private var animatedWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(stage.name)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(AppFormatter.integer(stage.count))
                    .font(AppTypography.metricValue)
                    .foregroundColor(AppColors.accentBlue)
            }

            GeometryReader { geo in
                let fraction = maxCount > 0 ? stage.count / maxCount : 0
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.accentBlue.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: animatedWidth)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                            animatedWidth = geo.size.width * fraction
                        }
                    }
                    .onChange(of: stage.count) { _, _ in
                        let fraction2 = maxCount > 0 ? stage.count / maxCount : 0
                        withAnimation(.easeOut(duration: 0.5)) {
                            animatedWidth = geo.size.width * fraction2
                        }
                    }
            }
            .frame(height: 28)

            HStack {
                if stage.dropOff > 0 {
                    Label(
                        "\(AppFormatter.percent(stage.dropOff)) drop-off",
                        systemImage: "arrow.down.right"
                    )
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.lossRed.opacity(0.8))
                }
                Spacer()
                Text("\(AppFormatter.decimal(stage.percentage, places: 2))% of total")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.medium, style: .continuous)
                .fill(AppColors.backgroundCard)
        )
    }
}

// MARK: - Disclaimer Footer

struct DisclaimerFooter: View {
    var body: some View {
        Text(AppConstants.disclaimer)
            .font(.system(size: 9, weight: .regular))
            .foregroundColor(AppColors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxxl)

            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus")
                }
                .buttonStyle(GlowButtonStyle())
                .padding(.top, AppSpacing.md)
            }
        }
        .padding(AppSpacing.xxxl)
    }
}

// MARK: - Campaign Card

struct CampaignCard: View {
    let campaign: CampaignEntity

    var body: some View {
        let m = campaign.metrics

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(campaign.name)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    if let platform = campaign.platform, !platform.isEmpty {
                        Text(platform)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.accentBlue.opacity(0.7))
                    }
                }
                Spacer()
                Text(campaign.updatedAt, style: .date)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }

            Divider().background(AppColors.divider)

            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                    Text(AppFormatter.currency(campaign.budget, symbol: campaign.currency))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Profit")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                    Text(AppFormatter.currency(m.profit, symbol: campaign.currency))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.metricColor(for: m.profit))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("ROAS")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                    Text(AppFormatter.roas(m.roas))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.roasColor(m.roas))
                }
            }
        }
        .cardStyle()
    }
}
