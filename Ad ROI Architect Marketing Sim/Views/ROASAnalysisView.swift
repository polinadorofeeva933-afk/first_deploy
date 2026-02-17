import SwiftUI
import Charts

// MARK: - ROAS Analysis View

struct ROASAnalysisView: View {
    let budget: Double
    let cpm: Double
    let ctr: Double
    let cr: Double
    let avgCheck: Double
    let currency: String

    @State private var adjustedBudget: Double = 0
    @State private var appeared = false

    private var metrics: CampaignMetrics {
        MarketingEngine.calculate(budget: adjustedBudget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Primary KPIs
                primaryKPIs

                // Budget slider
                budgetSlider

                // Profitability breakdown
                profitabilityBreakdown

                // Break-even chart
                breakEvenChartSection

                // CTR Sensitivity
                sensitivitySection

                // Max CPC Analysis
                maxCPCSection

                // Insights
                insightsSection

                DisclaimerFooter()
            }
            .padding()
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("ROI / ROAS Analysis")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            adjustedBudget = budget
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: Primary KPIs

    private var primaryKPIs: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                LargeKPICard(
                    title: "ROAS",
                    value: AppFormatter.roas(metrics.roas),
                    subtitle: metrics.roasCategory.rawValue,
                    valueColor: AppColors.roasColor(metrics.roas),
                    icon: "chart.line.uptrend.xyaxis"
                )

                LargeKPICard(
                    title: "ROI",
                    value: AppFormatter.percent(metrics.roi),
                    subtitle: metrics.isProfitable ? "Profitable" : "Losing",
                    valueColor: AppColors.metricColor(for: metrics.roi),
                    icon: "percent"
                )
            }

            HStack(spacing: AppSpacing.md) {
                LargeKPICard(
                    title: "Profit",
                    value: AppFormatter.currency(metrics.profit, symbol: currency),
                    valueColor: AppColors.metricColor(for: metrics.profit),
                    icon: metrics.isProfitable ? "arrow.up.right" : "arrow.down.right"
                )

                LargeKPICard(
                    title: "Revenue",
                    value: AppFormatter.currency(metrics.revenue, symbol: currency),
                    valueColor: AppColors.textPrimary,
                    icon: "banknote"
                )
            }
        }
    }

    // MARK: Budget Slider

    private var budgetSlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Adjust Budget")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(AppFormatter.currencyFull(adjustedBudget, symbol: currency))
                    .font(AppTypography.metricValue)
                    .foregroundColor(AppColors.accentBlue)
            }

            Slider(value: $adjustedBudget, in: max(100, budget * 0.1)...(budget * 3), step: max(100, budget * 0.05))
                .tint(AppColors.accentBlue)

            HStack {
                Text(AppFormatter.currency(budget * 0.1, symbol: currency))
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text(AppFormatter.currency(budget * 3, symbol: currency))
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .cardStyle()
    }

    // MARK: Profitability Breakdown

    private var profitabilityBreakdown: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Profitability Breakdown", icon: "chart.pie.fill")

            VStack(spacing: 0) {
                MetricRow(label: "Ad Spend (Budget)", value: AppFormatter.currencyFull(adjustedBudget, symbol: currency), valueColor: AppColors.lossRed)
                MetricRow(label: "Generated Revenue", value: AppFormatter.currencyFull(metrics.revenue, symbol: currency), valueColor: AppColors.profitGreen)
                Divider().background(AppColors.divider)
                MetricRow(label: "Net Profit / Loss", value: AppFormatter.currencyFull(metrics.profit, symbol: currency), valueColor: AppColors.metricColor(for: metrics.profit), isBold: true)
                Divider().background(AppColors.divider)
                MetricRow(label: "Return per $1 Spent", value: AppFormatter.roas(metrics.roas), valueColor: AppColors.roasColor(metrics.roas))
                MetricRow(label: "Wasted Spend", value: AppFormatter.currencyFull(metrics.wastedSpend, symbol: currency), valueColor: metrics.wastedSpend > 0 ? AppColors.lossRed : AppColors.profitGreen)
            }
            .cardStyle()
        }
    }

    // MARK: Break-even Chart

    private var breakEvenChartSection: some View {
        let maxBudget = adjustedBudget * 2.5
        let points = MarketingEngine.breakEvenPoints(
            cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck, maxBudget: maxBudget
        )

        return VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Break-even Analysis", subtitle: "Profit trajectory as budget scales", icon: "chart.xyaxis.line")

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    AreaMark(
                        x: .value("Budget", point.budget),
                        yStart: .value("Zero", 0),
                        yEnd: .value("Profit", point.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                point.profit >= 0 ? AppColors.profitGreen.opacity(0.25) : AppColors.lossRed.opacity(0.25),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Budget", point.budget),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(point.profit >= 0 ? AppColors.profitGreen : AppColors.lossRed)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }

                // Break-even line
                RuleMark(y: .value("Break-even", 0))
                    .foregroundStyle(AppColors.warningYellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Break-even")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.warningYellow)
                            .padding(.horizontal, 4)
                    }

                // Current budget marker
                RuleMark(x: .value("Current", adjustedBudget))
                    .foregroundStyle(AppColors.accentBlue.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
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
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(AppFormatter.currency(v, symbol: currency))
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 240)
            .cardStyle()
        }
    }

    // MARK: CTR Sensitivity

    private var sensitivitySection: some View {
        let data = MarketingEngine.sensitivityCTR(
            budget: adjustedBudget, cpm: cpm, baseCTR: ctr,
            cr: cr, avgCheck: avgCheck
        )

        return VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "CTR Sensitivity", subtitle: "How ROAS changes with different CTR values", icon: "waveform.path.ecg")

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                    BarMark(
                        x: .value("CTR", "\(AppFormatter.decimal(point.ctr, places: 1))%"),
                        y: .value("ROAS", point.roas)
                    )
                    .foregroundStyle(
                        point.roas >= 1.0 ? AppColors.profitGreen.opacity(0.7) : AppColors.lossRed.opacity(0.7)
                    )
                    .cornerRadius(4)
                }

                RuleMark(y: .value("Break-even", 1.0))
                    .foregroundStyle(AppColors.warningYellow.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(AppFormatter.decimal(v, places: 1))x")
                                .font(.system(size: 9))
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
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .cardStyle()
        }
    }

    // MARK: Max CPC

    private var maxCPCSection: some View {
        let maxCPC = metrics.maxCPC
        let currentCPC = metrics.cpc
        let isOverLimit = currentCPC > maxCPC

        return VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Max CPC Analysis", icon: "exclamationmark.triangle.fill")

            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current CPC")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(AppFormatter.currencyFull(currentCPC, symbol: currency))
                            .font(AppTypography.kpiSmall)
                            .foregroundColor(isOverLimit ? AppColors.lossRed : AppColors.profitGreen)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max CPC (break-even)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(AppFormatter.currencyFull(maxCPC, symbol: currency))
                            .font(AppTypography.kpiSmall)
                            .foregroundColor(AppColors.warningYellow)
                    }
                }

                // Visual bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.backgroundInput)

                        let maxVal = max(currentCPC, maxCPC) * 1.3
                        let cpcWidth = min(geo.size.width, geo.size.width * (currentCPC / maxVal))
                        let maxWidth = min(geo.size.width, geo.size.width * (maxCPC / maxVal))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isOverLimit ? AppColors.lossRed.opacity(0.4) : AppColors.profitGreen.opacity(0.4))
                            .frame(width: cpcWidth)

                        // Max CPC marker
                        Rectangle()
                            .fill(AppColors.warningYellow)
                            .frame(width: 2)
                            .offset(x: maxWidth)
                    }
                }
                .frame(height: 20)

                if isOverLimit {
                    Text("At current CR of \(AppFormatter.percent(cr)), max CPC should not exceed \(AppFormatter.currencyFull(maxCPC, symbol: currency)). Your CPC is \(AppFormatter.percent((currentCPC - maxCPC) / maxCPC * 100)) above the limit.")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.lossRed.opacity(0.8))
                } else {
                    Text("CPC is within profitable range. You have \(AppFormatter.currencyFull(maxCPC - currentCPC, symbol: currency)) of margin before break-even.")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.profitGreen.opacity(0.8))
                }
            }
            .cardStyle()
        }
    }

    // MARK: Insights

    private var insightsSection: some View {
        let insights = MarketingEngine.insights(for: metrics, ctr: ctr, cr: cr, avgCheck: avgCheck)
        return Group {
            if !insights.isEmpty {
                SectionHeader(title: "Advisory Insights", icon: "lightbulb.fill")
                VStack(spacing: AppSpacing.sm) {
                    ForEach(insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ROASAnalysisView(
            budget: 10000, cpm: 8.0, ctr: 2.5,
            cr: 3.0, avgCheck: 150, currency: "$"
        )
    }
}
