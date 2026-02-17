import SwiftUI
import Charts

// MARK: - Forward Planner View

struct ForwardPlannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let editCampaign: CampaignEntity?

    @State private var name: String = ""
    @State private var budgetStr: String = ""
    @State private var cpmStr: String = ""
    @State private var ctrStr: String = ""
    @State private var crStr: String = ""
    @State private var avgCheckStr: String = ""
    @State private var currency: String = "$"
    @State private var platform: String = ""
    @State private var notes: String = ""
    @State private var showSaveConfirmation = false
    @State private var currentStep = 0

    private var budget: Double { Double(budgetStr) ?? 0 }
    private var cpm: Double { Double(cpmStr) ?? 0 }
    private var ctr: Double { Double(ctrStr) ?? 0 }
    private var cr: Double { Double(crStr) ?? 0 }
    private var avgCheck: Double { Double(avgCheckStr) ?? 0 }

    private var metrics: CampaignMetrics {
        MarketingEngine.calculate(budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck)
    }

    private var isValid: Bool {
        budget > 0 && cpm > 0 && ctr > 0 && cr > 0 && avgCheck > 0 && !name.isEmpty
    }

    private let steps = ["Budget", "CPM", "CTR", "CR", "Check", "Review"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Step indicator
                        stepIndicator

                        // Input fields
                        inputSection

                        // Live calculation preview
                        if budget > 0 && cpm > 0 {
                            livePreview
                        }

                        // Insights
                        if isValid {
                            insightsSection
                        }

                        // Save button
                        if isValid {
                            saveButton
                        }

                        DisclaimerFooter()
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(editCampaign != nil ? "Edit Campaign" : "Forward Planner")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .onAppear { loadExistingData() }
            .alert("Campaign Saved", isPresented: $showSaveConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your campaign \"\(name)\" has been saved successfully.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stepColor(for: index))
                        .frame(height: 3)

                    Text(steps[index])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(stepColor(for: index))
                }
            }
        }
    }

    private func stepColor(for index: Int) -> Color {
        if index < currentStep { return AppColors.profitGreen }
        if index == currentStep { return AppColors.accentBlue }
        return AppColors.textTertiary.opacity(0.5)
    }

    // MARK: Input Section

    private var inputSection: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Campaign Setup", icon: "pencil.and.outline")

            LabeledInputField(
                label: "Campaign Name",
                placeholder: "e.g. Summer Sale 2025",
                value: $name,
                keyboardType: .default,
                validateNumeric: false
            )
            .onChange(of: name) { _, _ in updateStep() }

            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Currency")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Picker("Currency", selection: $currency) {
                        ForEach(AppConstants.defaultCurrencies, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accentBlue)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                            .fill(AppColors.backgroundInput)
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Platform")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Picker("Platform", selection: $platform) {
                        Text("None").tag("")
                        ForEach(AppConstants.platformNames, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accentBlue)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                            .fill(AppColors.backgroundInput)
                    )
                }
            }

            SectionHeader(title: "Funnel Parameters", subtitle: "All fields required for calculation", icon: "function")

            LabeledInputField(
                label: "Budget",
                placeholder: "10000",
                value: $budgetStr,
                prefix: currency,
                info: "Total ad spend"
            )
            .onChange(of: budgetStr) { _, _ in updateStep() }

            LabeledInputField(
                label: "CPM (Cost per 1000 Impressions)",
                placeholder: "8.50",
                value: $cpmStr,
                prefix: currency,
                info: "Cost per mille"
            )
            .onChange(of: cpmStr) { _, _ in updateStep() }

            LabeledInputField(
                label: "CTR (Click-Through Rate)",
                placeholder: "2.5",
                value: $ctrStr,
                suffix: "%",
                info: "Clicks / Impressions"
            )
            .onChange(of: ctrStr) { _, _ in updateStep() }

            LabeledInputField(
                label: "CR (Conversion Rate)",
                placeholder: "3.0",
                value: $crStr,
                suffix: "%",
                info: "Leads / Clicks"
            )
            .onChange(of: crStr) { _, _ in updateStep() }

            LabeledInputField(
                label: "Average Check",
                placeholder: "150",
                value: $avgCheckStr,
                prefix: currency,
                info: "Revenue per conversion"
            )
            .onChange(of: avgCheckStr) { _, _ in updateStep() }
        }
    }

    // MARK: Live Preview

    private var livePreview: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(title: "Real-time Forecast", icon: "bolt.fill")

            // Key metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                MetricCard(
                    title: "Impressions",
                    value: AppFormatter.integer(metrics.impressions),
                    icon: "eye.fill"
                )
                MetricCard(
                    title: "Clicks",
                    value: AppFormatter.integer(metrics.clicks),
                    icon: "cursorarrow.click.2"
                )
                MetricCard(
                    title: "CPC",
                    value: AppFormatter.currency(metrics.cpc, symbol: currency),
                    valueColor: metrics.cpc > metrics.maxCPC ? AppColors.lossRed : AppColors.textPrimary,
                    icon: "dollarsign.circle"
                )
                MetricCard(
                    title: "Leads / Sales",
                    value: AppFormatter.integer(metrics.leads),
                    icon: "person.fill.checkmark"
                )
                MetricCard(
                    title: "Revenue",
                    value: AppFormatter.currency(metrics.revenue, symbol: currency),
                    icon: "banknote"
                )
                MetricCard(
                    title: "CPL / CAC",
                    value: AppFormatter.currency(metrics.cpl, symbol: currency),
                    valueColor: metrics.cpl > avgCheck ? AppColors.lossRed : AppColors.textPrimary,
                    icon: "person.badge.minus"
                )
            }

            // Profit & ROAS highlight
            HStack(spacing: AppSpacing.md) {
                LargeKPICard(
                    title: "Profit",
                    value: AppFormatter.currency(metrics.profit, symbol: currency),
                    valueColor: AppColors.metricColor(for: metrics.profit),
                    icon: metrics.isProfitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
                )
                LargeKPICard(
                    title: "ROAS",
                    value: AppFormatter.roas(metrics.roas),
                    subtitle: metrics.roasCategory.rawValue,
                    valueColor: AppColors.roasColor(metrics.roas),
                    icon: "chart.line.uptrend.xyaxis"
                )
            }

            // Mini chart
            if isValid {
                miniBreakEvenChart
            }
        }
    }

    // MARK: Mini Break-even Chart

    private var miniBreakEvenChart: some View {
        let points = MarketingEngine.breakEvenPoints(
            cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck, maxBudget: budget * 1.5
        )

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Profit vs Budget")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Budget", point.budget),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.lossRed, AppColors.profitGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Budget", point.budget),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accentBlue.opacity(0.2), AppColors.accentBlue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                RuleMark(y: .value("Break-even", 0))
                    .foregroundStyle(AppColors.warningYellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
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
            .frame(height: 180)
        }
        .cardStyle()
    }

    // MARK: Insights

    private var insightsSection: some View {
        let insights = MarketingEngine.insights(for: metrics, ctr: ctr, cr: cr, avgCheck: avgCheck)
        return Group {
            if !insights.isEmpty {
                SectionHeader(title: "Insights", icon: "lightbulb.fill")
                VStack(spacing: AppSpacing.sm) {
                    ForEach(insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
    }

    // MARK: Save

    private var saveButton: some View {
        Button {
            saveCampaign()
        } label: {
            HStack {
                Image(systemName: editCampaign != nil ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                Text(editCampaign != nil ? "Update Campaign" : "Save Campaign")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlowButtonStyle())
        .padding(.top, AppSpacing.md)
    }

    // MARK: Logic

    private func updateStep() {
        if avgCheck > 0 { currentStep = 5 }
        else if cr > 0 { currentStep = 4 }
        else if ctr > 0 { currentStep = 3 }
        else if cpm > 0 { currentStep = 2 }
        else if budget > 0 { currentStep = 1 }
        else { currentStep = 0 }
    }

    private func loadExistingData() {
        guard let c = editCampaign else { return }
        name = c.name
        budgetStr = String(c.budget)
        cpmStr = String(c.cpm)
        ctrStr = String(c.ctr)
        crStr = String(c.cr)
        avgCheckStr = String(c.avgCheck)
        currency = c.currency
        platform = c.platform ?? ""
        notes = c.notes ?? ""
        updateStep()
    }

    private func saveCampaign() {
        if let existing = editCampaign {
            existing.name = name
            existing.budget = budget
            existing.cpm = cpm
            existing.ctr = ctr
            existing.cr = cr
            existing.avgCheck = avgCheck
            existing.currency = currency
            existing.platform = platform.isEmpty ? nil : platform
            existing.notes = notes.isEmpty ? nil : notes
            existing.updatedAt = Date()
        } else {
            _ = CampaignEntity.create(
                in: viewContext,
                name: name,
                budget: budget,
                cpm: cpm,
                ctr: ctr,
                cr: cr,
                avgCheck: avgCheck,
                currency: currency,
                platform: platform.isEmpty ? nil : platform,
                notes: notes.isEmpty ? nil : notes
            )
        }
        PersistenceController.shared.save()
        showSaveConfirmation = true
    }
}

#Preview {
    ForwardPlannerView(editCampaign: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
