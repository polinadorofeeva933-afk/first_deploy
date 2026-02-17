import SwiftUI
import Charts

// MARK: - Compare Tool View (A/B Test)

struct CompareToolView: View {
    @State private var scenarioA = ScenarioInput(name: "Scenario A")
    @State private var scenarioB = ScenarioInput(name: "Scenario B")
    @State private var currency = "$"
    @State private var showResults = false

    private var metricsA: CampaignMetrics {
        MarketingEngine.calculate(
            budget: scenarioA.budget, cpm: scenarioA.cpm,
            ctr: scenarioA.ctr, cr: scenarioA.cr, avgCheck: scenarioA.avgCheck
        )
    }

    private var metricsB: CampaignMetrics {
        MarketingEngine.calculate(
            budget: scenarioB.budget, cpm: scenarioB.cpm,
            ctr: scenarioB.ctr, cr: scenarioB.cr, avgCheck: scenarioB.avgCheck
        )
    }

    private var bothValid: Bool {
        scenarioA.isValid && scenarioB.isValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        headerInfo

                        // Currency selector
                        HStack {
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
                            Spacer()
                        }

                        // Side by side input
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            scenarioInputCard(scenario: $scenarioA, label: "A", color: AppColors.accentBlue)
                            scenarioInputCard(scenario: $scenarioB, label: "B", color: AppColors.profitGreen)
                        }

                        if bothValid {
                            // Comparison results
                            comparisonResults
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            // Charts
                            comparisonChart

                            // Winner
                            winnerCard

                            // Detailed comparison table
                            detailedComparison
                        }

                        DisclaimerFooter()
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Compare Tool")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: bothValid)
    }

    // MARK: Header

    private var headerInfo: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 28))
                .foregroundColor(AppColors.accentBlue)
            Text("Compare two campaign scenarios side by side. Enter parameters for each hypothesis to identify the stronger strategy.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .cardStyle()
    }

    // MARK: Scenario Input Card

    private func scenarioInputCard(scenario: Binding<ScenarioInput>, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text("Scenario \(label)")
                    .font(AppTypography.caption)
                    .foregroundColor(color)
            }

            compactInput("Budget", value: scenario.budgetStr, prefix: currency)
            compactInput("CPM", value: scenario.cpmStr, prefix: currency)
            compactInput("CTR %", value: scenario.ctrStr, suffix: "%")
            compactInput("CR %", value: scenario.crStr, suffix: "%")
            compactInput("Avg Check", value: scenario.avgCheckStr, prefix: currency)
        }
        .cardStyle(padding: AppSpacing.md)
    }

    private func compactInput(_ label: String, value: Binding<String>, prefix: String? = nil, suffix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AppColors.textTertiary)

            HStack(spacing: 4) {
                if let prefix {
                    Text(prefix)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                TextField("0", text: value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(AppColors.backgroundInput)
            )
        }
    }

    // MARK: Comparison Results

    private var comparisonResults: some View {
        VStack(spacing: AppSpacing.md) {
            SectionHeader(title: "Key Metrics Comparison", icon: "chart.bar.xaxis")

            // ROAS comparison
            comparisonRow(
                metric: "ROAS",
                valueA: AppFormatter.roas(metricsA.roas),
                valueB: AppFormatter.roas(metricsB.roas),
                colorA: AppColors.roasColor(metricsA.roas),
                colorB: AppColors.roasColor(metricsB.roas),
                aWins: metricsA.roas > metricsB.roas
            )

            comparisonRow(
                metric: "Profit",
                valueA: AppFormatter.currency(metricsA.profit, symbol: currency),
                valueB: AppFormatter.currency(metricsB.profit, symbol: currency),
                colorA: AppColors.metricColor(for: metricsA.profit),
                colorB: AppColors.metricColor(for: metricsB.profit),
                aWins: metricsA.profit > metricsB.profit
            )

            comparisonRow(
                metric: "ROI",
                valueA: AppFormatter.percent(metricsA.roi),
                valueB: AppFormatter.percent(metricsB.roi),
                colorA: AppColors.metricColor(for: metricsA.roi),
                colorB: AppColors.metricColor(for: metricsB.roi),
                aWins: metricsA.roi > metricsB.roi
            )

            comparisonRow(
                metric: "CPC",
                valueA: AppFormatter.currency(metricsA.cpc, symbol: currency),
                valueB: AppFormatter.currency(metricsB.cpc, symbol: currency),
                colorA: AppColors.textPrimary,
                colorB: AppColors.textPrimary,
                aWins: metricsA.cpc < metricsB.cpc // Lower is better
            )

            comparisonRow(
                metric: "CPL",
                valueA: AppFormatter.currency(metricsA.cpl, symbol: currency),
                valueB: AppFormatter.currency(metricsB.cpl, symbol: currency),
                colorA: AppColors.textPrimary,
                colorB: AppColors.textPrimary,
                aWins: metricsA.cpl < metricsB.cpl
            )
        }
    }

    private func comparisonRow(metric: String, valueA: String, valueB: String, colorA: Color, colorB: Color, aWins: Bool) -> some View {
        HStack {
            HStack(spacing: 4) {
                if aWins {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.warningYellow)
                }
                Text(valueA)
                    .font(AppTypography.metricValue)
                    .foregroundColor(colorA)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(spacing: 2) {
                Text(metric)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(width: 60)

            HStack(spacing: 4) {
                Text(valueB)
                    .font(AppTypography.metricValue)
                    .foregroundColor(colorB)
                if !aWins {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.warningYellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppColors.backgroundCard)
        )
    }

    // MARK: Chart

    private var comparisonChart: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Visual Comparison", icon: "chart.bar.fill")

            Chart {
                BarMark(
                    x: .value("Metric", "Revenue"),
                    y: .value("Value", metricsA.revenue)
                )
                .foregroundStyle(AppColors.accentBlue.opacity(0.7))
                .position(by: .value("Scenario", "A"))

                BarMark(
                    x: .value("Metric", "Revenue"),
                    y: .value("Value", metricsB.revenue)
                )
                .foregroundStyle(AppColors.profitGreen.opacity(0.7))
                .position(by: .value("Scenario", "B"))

                BarMark(
                    x: .value("Metric", "Profit"),
                    y: .value("Value", max(0, metricsA.profit))
                )
                .foregroundStyle(AppColors.accentBlue.opacity(0.7))
                .position(by: .value("Scenario", "A"))

                BarMark(
                    x: .value("Metric", "Profit"),
                    y: .value("Value", max(0, metricsB.profit))
                )
                .foregroundStyle(AppColors.profitGreen.opacity(0.7))
                .position(by: .value("Scenario", "B"))

                BarMark(
                    x: .value("Metric", "Leads"),
                    y: .value("Value", metricsA.leads)
                )
                .foregroundStyle(AppColors.accentBlue.opacity(0.7))
                .position(by: .value("Scenario", "A"))

                BarMark(
                    x: .value("Metric", "Leads"),
                    y: .value("Value", metricsB.leads)
                )
                .foregroundStyle(AppColors.profitGreen.opacity(0.7))
                .position(by: .value("Scenario", "B"))
            }
            .chartForegroundStyleScale([
                "A": AppColors.accentBlue.opacity(0.7),
                "B": AppColors.profitGreen.opacity(0.7)
            ])
            .chartLegend(position: .top, alignment: .trailing)
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

    // MARK: Winner

    private var winnerCard: some View {
        let aProfit = metricsA.profit
        let bProfit = metricsB.profit
        let aROAS = metricsA.roas
        let bROAS = metricsB.roas

        let aScore = (aProfit > bProfit ? 1 : 0) + (aROAS > bROAS ? 1 : 0) + (metricsA.cpc < metricsB.cpc ? 1 : 0)
        let winner = aScore >= 2 ? "A" : "B"
        let winColor = winner == "A" ? AppColors.accentBlue : AppColors.profitGreen

        return VStack(spacing: AppSpacing.md) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundColor(AppColors.warningYellow)

            Text("Scenario \(winner) Wins")
                .font(AppTypography.headline)
                .foregroundColor(winColor)

            Text("Based on profit, ROAS, and cost efficiency analysis.")
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: Detailed Comparison

    private var detailedComparison: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Full Metrics Table", icon: "tablecells")

            VStack(spacing: 0) {
                detailRow("Impressions", a: AppFormatter.integer(metricsA.impressions), b: AppFormatter.integer(metricsB.impressions))
                detailRow("Clicks", a: AppFormatter.integer(metricsA.clicks), b: AppFormatter.integer(metricsB.clicks))
                detailRow("CPC", a: AppFormatter.currency(metricsA.cpc, symbol: currency), b: AppFormatter.currency(metricsB.cpc, symbol: currency))
                detailRow("Leads", a: AppFormatter.integer(metricsA.leads), b: AppFormatter.integer(metricsB.leads))
                detailRow("CPL", a: AppFormatter.currency(metricsA.cpl, symbol: currency), b: AppFormatter.currency(metricsB.cpl, symbol: currency))
                detailRow("Revenue", a: AppFormatter.currency(metricsA.revenue, symbol: currency), b: AppFormatter.currency(metricsB.revenue, symbol: currency))
                detailRow("Profit", a: AppFormatter.currency(metricsA.profit, symbol: currency), b: AppFormatter.currency(metricsB.profit, symbol: currency))
                detailRow("ROAS", a: AppFormatter.roas(metricsA.roas), b: AppFormatter.roas(metricsB.roas))
                detailRow("ROI", a: AppFormatter.percent(metricsA.roi), b: AppFormatter.percent(metricsB.roi))
                detailRow("Max CPC", a: AppFormatter.currency(metricsA.maxCPC, symbol: currency), b: AppFormatter.currency(metricsB.maxCPC, symbol: currency))
            }
            .cardStyle(padding: AppSpacing.sm)
        }
    }

    private func detailRow(_ label: String, a: String, b: String) -> some View {
        HStack {
            Text(a)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(AppColors.accentBlue)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 70, alignment: .center)

            Text(b)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(AppColors.profitGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Scenario Input Model

struct ScenarioInput {
    var name: String
    var budgetStr: String = ""
    var cpmStr: String = ""
    var ctrStr: String = ""
    var crStr: String = ""
    var avgCheckStr: String = ""

    var budget: Double { Double(budgetStr) ?? 0 }
    var cpm: Double { Double(cpmStr) ?? 0 }
    var ctr: Double { Double(ctrStr) ?? 0 }
    var cr: Double { Double(crStr) ?? 0 }
    var avgCheck: Double { Double(avgCheckStr) ?? 0 }

    var isValid: Bool {
        budget > 0 && cpm > 0 && ctr > 0 && cr > 0 && avgCheck > 0
    }
}

#Preview {
    CompareToolView()
}
