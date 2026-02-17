import SwiftUI
import Charts

// MARK: - Funnel Visualizer View

struct FunnelVisualizerView: View {
    let budget: Double
    let cpm: Double
    let ctr: Double
    let cr: Double
    let avgCheck: Double
    let currency: String

    @State private var adjustedCTR: Double = 0
    @State private var adjustedCR: Double = 0
    @State private var adjustedBudget: Double = 0
    @State private var appeared = false

    private var stages: [FunnelStage] {
        MarketingEngine.funnelStages(
            budget: adjustedBudget, cpm: cpm,
            ctr: adjustedCTR, cr: adjustedCR, avgCheck: avgCheck
        )
    }

    private var metrics: CampaignMetrics {
        MarketingEngine.calculate(
            budget: adjustedBudget, cpm: cpm,
            ctr: adjustedCTR, cr: adjustedCR, avgCheck: avgCheck
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Visual funnel
                funnelVisualization

                // Interactive sliders
                sliderControls

                // Cost per stage
                costPerStage

                // Funnel chart
                funnelBarChart

                // Revenue waterfall
                revenueWaterfall

                DisclaimerFooter()
            }
            .padding()
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Funnel Visualizer")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            adjustedCTR = ctr
            adjustedCR = cr
            adjustedBudget = budget
            withAnimation(.easeOut(duration: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: Visual Funnel

    private var funnelVisualization: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - AppSpacing.lg * 2

            VStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    let maxCount = stages.first?.count ?? 1
                    let fraction = maxCount > 0 ? stage.count / maxCount : 0
                    let color = funnelColor(for: index)

                    VStack(spacing: 0) {
                        // Funnel bar
                        HStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.7), color.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: appeared ? max(60, CGFloat(fraction) * availableWidth) : 60,
                                        height: 52
                                    )
                                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.15), value: appeared)

                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: stageIcon(for: index))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(stage.name)
                                            .font(AppTypography.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(AppFormatter.integer(stage.count))
                                            .font(AppTypography.metricValue)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            Spacer()
                        }

                        // Drop-off indicator
                        if stage.dropOff > 0 {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 10))
                                Text("-\(AppFormatter.decimal(stage.dropOff, places: 1))% drop-off")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(AppColors.lossRed.opacity(0.7))
                            .padding(.vertical, 6)
                        } else if index < stages.count - 1 {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
            .cardStyle()
        }
        .frame(height: CGFloat(stages.count) * 80)
    }

    // MARK: Slider Controls

    private var sliderControls: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Adjust Funnel", subtitle: "Drag to see real-time changes", icon: "slider.horizontal.3")

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Budget")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppFormatter.currency(adjustedBudget, symbol: currency))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                Slider(value: $adjustedBudget, in: max(100, budget * 0.1)...(budget * 3), step: max(50, budget * 0.05))
                    .tint(AppColors.accentBlue)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("CTR")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppFormatter.percent(adjustedCTR))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                Slider(value: $adjustedCTR, in: 0.1...10.0, step: 0.1)
                    .tint(AppColors.accentBlue)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Conversion Rate")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppFormatter.percent(adjustedCR))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                Slider(value: $adjustedCR, in: 0.1...20.0, step: 0.1)
                    .tint(AppColors.accentBlue)
            }
            .cardStyle()
        }
    }

    // MARK: Cost Per Stage

    private var costPerStage: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Cost Per Stage", icon: "dollarsign.arrow.circlepath")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                let impressions = stages.first?.count ?? 0
                let clicks = stages.count > 1 ? stages[1].count : 0
                let leads = stages.count > 2 ? stages[2].count : 0

                MetricCard(
                    title: "Cost per Impression",
                    value: AppFormatter.currency(impressions > 0 ? adjustedBudget / impressions : 0, symbol: currency),
                    icon: "eye"
                )
                MetricCard(
                    title: "Cost per Click",
                    value: AppFormatter.currency(clicks > 0 ? adjustedBudget / clicks : 0, symbol: currency),
                    valueColor: metrics.cpc > metrics.maxCPC ? AppColors.lossRed : AppColors.textPrimary,
                    icon: "cursorarrow.click"
                )
                MetricCard(
                    title: "Cost per Lead",
                    value: AppFormatter.currency(leads > 0 ? adjustedBudget / leads : 0, symbol: currency),
                    valueColor: metrics.cpl > avgCheck ? AppColors.lossRed : AppColors.textPrimary,
                    icon: "person"
                )
                MetricCard(
                    title: "Revenue per Lead",
                    value: AppFormatter.currency(avgCheck, symbol: currency),
                    valueColor: AppColors.profitGreen,
                    icon: "banknote"
                )
            }
        }
    }

    // MARK: Funnel Bar Chart

    private var funnelBarChart: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Funnel Stages", icon: "chart.bar.fill")

            Chart {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    BarMark(
                        x: .value("Stage", stage.name),
                        y: .value("Count", stage.count)
                    )
                    .foregroundStyle(funnelColor(for: index).opacity(0.7))
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(AppFormatter.integer(stage.count))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(funnelColor(for: index))
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.2))
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(AppFormatter.integer(v))
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(String.self) {
                            Text(v)
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 220)
            .cardStyle()
        }
    }

    // MARK: Revenue Waterfall

    private var revenueWaterfall: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Revenue vs Cost", icon: "arrow.left.arrow.right")

            HStack(spacing: AppSpacing.md) {
                VStack(spacing: AppSpacing.sm) {
                    Text("Budget Spent")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(AppFormatter.currency(adjustedBudget, symbol: currency))
                        .font(AppTypography.kpiSmall)
                        .foregroundColor(AppColors.lossRed)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.textTertiary)

                VStack(spacing: AppSpacing.sm) {
                    Text("Revenue")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(AppFormatter.currency(metrics.revenue, symbol: currency))
                        .font(AppTypography.kpiSmall)
                        .foregroundColor(AppColors.profitGreen)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "equal")
                    .foregroundColor(AppColors.textTertiary)

                VStack(spacing: AppSpacing.sm) {
                    Text("Profit")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(AppFormatter.currency(metrics.profit, symbol: currency))
                        .font(AppTypography.kpiSmall)
                        .foregroundColor(AppColors.metricColor(for: metrics.profit))
                }
                .frame(maxWidth: .infinity)
            }
            .cardStyle()
        }
    }

    // MARK: Helpers

    private func funnelColor(for index: Int) -> Color {
        switch index {
        case 0: return AppColors.accentBlue
        case 1: return Color(red: 0.3, green: 0.7, blue: 1.0)
        case 2: return AppColors.warningYellow
        case 3: return AppColors.profitGreen
        default: return AppColors.accentBlue
        }
    }

    private func stageIcon(for index: Int) -> String {
        switch index {
        case 0: return "eye.fill"
        case 1: return "cursorarrow.click.2"
        case 2: return "person.fill.checkmark"
        case 3: return "bag.fill"
        default: return "circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        FunnelVisualizerView(
            budget: 10000, cpm: 8.0, ctr: 2.5,
            cr: 3.0, avgCheck: 150, currency: "$"
        )
    }
}
