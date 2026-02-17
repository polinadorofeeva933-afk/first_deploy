import SwiftUI
import Charts

// MARK: - Reverse Engineer View

struct ReverseEngineerView: View {
    @State private var desiredProfitStr: String = ""
    @State private var cpmStr: String = "8.0"
    @State private var ctr: Double = 2.0
    @State private var cr: Double = 3.0
    @State private var avgCheckStr: String = "150"
    @State private var currency: String = "$"
    @State private var animateResult = false

    private var desiredProfit: Double { Double(desiredProfitStr) ?? 0 }
    private var cpm: Double { Double(cpmStr) ?? 0 }
    private var avgCheck: Double { Double(avgCheckStr) ?? 0 }

    private var result: ReverseResult {
        MarketingEngine.reverseCalculate(
            desiredProfit: desiredProfit, cpm: cpm,
            ctr: ctr, cr: cr, avgCheck: avgCheck
        )
    }

    private var hasInput: Bool {
        desiredProfit > 0 && cpm > 0 && avgCheck > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        headerCard

                        inputSection

                        if hasInput {
                            sliderSection

                            resultSection
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            if result.isAchievable {
                                breakdownSection
                                breakEvenChart
                            }
                        }

                        DisclaimerFooter()
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Reverse Engineer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private var headerCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 28))
                .foregroundColor(AppColors.accentBlue)
            Text("Enter your desired profit and funnel parameters to reverse-calculate the required advertising budget.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .cardStyle()
    }

    // MARK: Input

    private var inputSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Target & Parameters", icon: "target")

            LabeledInputField(
                label: "Desired Profit",
                placeholder: "50000",
                value: $desiredProfitStr,
                prefix: currency,
                info: "Net profit target"
            )

            HStack(spacing: AppSpacing.md) {
                LabeledInputField(
                    label: "CPM",
                    placeholder: "8.0",
                    value: $cpmStr,
                    prefix: currency
                )
                LabeledInputField(
                    label: "Avg. Check",
                    placeholder: "150",
                    value: $avgCheckStr,
                    prefix: currency
                )
            }

            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Currency")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Picker("", selection: $currency) {
                        ForEach(AppConstants.defaultCurrencies, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accentBlue)
                }
                Spacer()
            }
        }
    }

    // MARK: Sliders

    private var sliderSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Adjust Conversion Funnel", subtitle: "Drag sliders to see dynamic changes", icon: "slider.horizontal.3")

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("CTR (Click-Through Rate)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppFormatter.percent(ctr))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                Slider(value: $ctr, in: 0.1...10.0, step: 0.1)
                    .tint(AppColors.accentBlue)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("CR (Conversion Rate)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppFormatter.percent(cr))
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                Slider(value: $cr, in: 0.1...20.0, step: 0.1)
                    .tint(AppColors.accentBlue)
            }
            .cardStyle()
        }
    }

    // MARK: Result

    private var resultSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Required Investment", icon: "banknote.fill")

            if result.isAchievable {
                LargeKPICard(
                    title: "Required Budget",
                    value: AppFormatter.currency(result.requiredBudget, symbol: currency),
                    subtitle: "To achieve \(AppFormatter.currency(desiredProfit, symbol: currency)) profit",
                    valueColor: AppColors.accentBlue,
                    icon: "dollarsign.circle.fill"
                )
                .onAppear {
                    withAnimation(.spring(response: 0.5)) {
                        animateResult = true
                    }
                }

                HStack(spacing: AppSpacing.md) {
                    MetricCard(
                        title: "ROAS",
                        value: AppFormatter.roas(result.effectiveROAS),
                        valueColor: AppColors.roasColor(result.effectiveROAS),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    MetricCard(
                        title: "ROI",
                        value: AppFormatter.percent(result.effectiveROI),
                        valueColor: AppColors.profitGreen,
                        icon: "percent"
                    )
                }
            } else {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.lossRed)

                    Text("Not Achievable")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.lossRed)

                    Text(result.reason)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .cardStyle()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: result.isAchievable)
    }

    // MARK: Breakdown

    private var breakdownSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Funnel Requirements", icon: "chart.bar.doc.horizontal")

            VStack(spacing: 0) {
                MetricRow(label: "Required Impressions", value: AppFormatter.integer(result.requiredImpressions))
                MetricRow(label: "Required Clicks", value: AppFormatter.integer(result.requiredClicks))
                MetricRow(label: "Required Leads / Sales", value: AppFormatter.integer(result.requiredLeads))
                MetricRow(label: "Total Revenue", value: AppFormatter.currencyFull(result.totalRevenue, symbol: currency), valueColor: AppColors.profitGreen)
                MetricRow(label: "Target Profit", value: AppFormatter.currencyFull(desiredProfit, symbol: currency), valueColor: AppColors.profitGreen, isBold: true)
            }
            .cardStyle()
        }
    }

    // MARK: Break-even Chart

    private var breakEvenChart: some View {
        let maxBudget = result.requiredBudget * 2
        let points = MarketingEngine.breakEvenPoints(
            cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck, maxBudget: maxBudget
        )

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Budget vs Profit", icon: "chart.xyaxis.line")

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    AreaMark(
                        x: .value("Budget", point.budget),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                point.profit >= 0 ? AppColors.profitGreen.opacity(0.3) : AppColors.lossRed.opacity(0.3),
                                AppColors.backgroundCard.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Budget", point.budget),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(AppColors.accentBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Target profit line
                RuleMark(y: .value("Target", desiredProfit))
                    .foregroundStyle(AppColors.profitGreen.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.profitGreen)
                    }

                // Required budget line
                RuleMark(x: .value("Required", result.requiredBudget))
                    .foregroundStyle(AppColors.accentBlue.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))

                // Zero line
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.warningYellow.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(AppFormatter.currency(v, symbol: currency))
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(AppFormatter.currency(v, symbol: currency))
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 220)
            .cardStyle()
        }
    }
}

#Preview {
    ReverseEngineerView()
}
