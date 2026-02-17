import SwiftUI
import CoreData

// MARK: - Campaign Hub View

struct CampaignHubView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CampaignEntity.updatedAt, ascending: false)],
        animation: .easeInOut
    )
    private var campaigns: FetchedResults<CampaignEntity>

    @State private var showNewCampaign = false
    @State private var selectedCampaign: CampaignEntity?
    @State private var showDeleteAlert = false
    @State private var campaignToDelete: CampaignEntity?
    @State private var searchText = ""

    private var filteredCampaigns: [CampaignEntity] {
        if searchText.isEmpty {
            return Array(campaigns)
        }
        return campaigns.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.platform ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                if campaigns.isEmpty {
                    EmptyStateView(
                        icon: "megaphone",
                        title: "No Campaigns Yet",
                        message: "Create your first campaign to start simulating ad performance and calculating ROI metrics.",
                        buttonTitle: "New Campaign",
                        action: { showNewCampaign = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            // Summary banner
                            summaryBanner
                                .padding(.horizontal)

                            // Search
                            if campaigns.count > 3 {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(AppColors.textTertiary)
                                    TextField("Search campaigns...", text: $searchText)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                                        .fill(AppColors.backgroundInput)
                                )
                                .padding(.horizontal)
                            }

                            // Campaign list
                            ForEach(filteredCampaigns, id: \.objectID) { campaign in
                                NavigationLink(value: campaign) {
                                    CampaignCard(campaign: campaign)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        campaignToDelete = campaign
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .padding(.horizontal)
                            }

                            DisclaimerFooter()
                                .padding(.top, AppSpacing.lg)
                        }
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Campaign Hub")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewCampaign = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
            }
            .sheet(isPresented: $showNewCampaign) {
                ForwardPlannerView(editCampaign: nil)
                    .environment(\.managedObjectContext, viewContext)
            }
            .navigationDestination(for: CampaignEntity.self) { campaign in
                CampaignDetailView(campaign: campaign)
            }
            .alert("Delete Campaign", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let campaign = campaignToDelete {
                        deleteCampaign(campaign)
                    }
                }
            } message: {
                Text("This action cannot be undone. All data for this campaign will be permanently removed.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Summary Banner

    private var summaryBanner: some View {
        let totalBudget = campaigns.reduce(0) { $0 + $1.budget }
        let totalProfit = campaigns.reduce(0) { $0 + $1.metrics.profit }
        let avgROAS = campaigns.isEmpty ? 0 : campaigns.reduce(0.0) { $0 + $1.metrics.roas } / Double(campaigns.count)
        let curr = campaigns.first?.currency ?? "$"

        return HStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Budget")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
                Text(AppFormatter.currency(totalBudget, symbol: curr))
                    .font(AppTypography.metricValue)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Total Profit")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
                Text(AppFormatter.currency(totalProfit, symbol: curr))
                    .font(AppTypography.metricValue)
                    .foregroundColor(AppColors.metricColor(for: totalProfit))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Avg ROAS")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
                Text(AppFormatter.roas(avgROAS))
                    .font(AppTypography.metricValue)
                    .foregroundColor(AppColors.roasColor(avgROAS))
            }
        }
        .cardStyle()
    }

    // MARK: Delete

    private func deleteCampaign(_ campaign: CampaignEntity) {
        withAnimation {
            viewContext.delete(campaign)
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Campaign Detail View

struct CampaignDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let campaign: CampaignEntity

    @State private var showEditSheet = false
    @State private var showExportSheet = false
    @State private var pdfData: Data?

    var body: some View {
        let m = campaign.metrics
        let c = campaign.currency

        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header KPIs
                HStack(spacing: AppSpacing.md) {
                    LargeKPICard(
                        title: "ROAS",
                        value: AppFormatter.roas(m.roas),
                        subtitle: m.roasCategory.description,
                        valueColor: AppColors.roasColor(m.roas),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    LargeKPICard(
                        title: "Profit",
                        value: AppFormatter.currency(m.profit, symbol: c),
                        subtitle: "ROI: \(AppFormatter.percent(m.roi))",
                        valueColor: AppColors.metricColor(for: m.profit),
                        icon: m.isProfitable ? "arrow.up.right" : "arrow.down.right"
                    )
                }

                // Input Parameters
                SectionHeader(title: "Input Parameters", icon: "slider.horizontal.3")
                VStack(spacing: 0) {
                    MetricRow(label: "Budget", value: AppFormatter.currencyFull(campaign.budget, symbol: c))
                    MetricRow(label: "CPM", value: AppFormatter.currencyFull(campaign.cpm, symbol: c))
                    MetricRow(label: "CTR", value: AppFormatter.percent(campaign.ctr))
                    MetricRow(label: "Conversion Rate", value: AppFormatter.percent(campaign.cr))
                    MetricRow(label: "Average Check", value: AppFormatter.currencyFull(campaign.avgCheck, symbol: c))
                }
                .cardStyle()

                // Calculated Metrics
                SectionHeader(title: "Performance Metrics", icon: "chart.bar.fill")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    MetricCard(title: "Impressions", value: AppFormatter.integer(m.impressions), icon: "eye.fill")
                    MetricCard(title: "Clicks", value: AppFormatter.integer(m.clicks), icon: "cursorarrow.click.2")
                    MetricCard(title: "CPC", value: AppFormatter.currency(m.cpc, symbol: c), icon: "dollarsign.circle")
                    MetricCard(title: "Leads", value: AppFormatter.integer(m.leads), icon: "person.fill.checkmark")
                    MetricCard(title: "CPL / CAC", value: AppFormatter.currency(m.cpl, symbol: c), icon: "person.badge.minus")
                    MetricCard(title: "Revenue", value: AppFormatter.currency(m.revenue, symbol: c), icon: "banknote")
                    MetricCard(
                        title: "Max CPC",
                        value: AppFormatter.currency(m.maxCPC, symbol: c),
                        subtitle: m.cpc > m.maxCPC ? "CPC exceeds limit!" : "Within range",
                        valueColor: m.cpc > m.maxCPC ? AppColors.lossRed : AppColors.profitGreen,
                        icon: "exclamationmark.triangle"
                    )
                    MetricCard(title: "Cost/Impression", value: AppFormatter.currency(m.costPerImpression, symbol: c), icon: "chart.dots.scatter")
                }

                // Insights
                let insights = MarketingEngine.insights(for: m, ctr: campaign.ctr, cr: campaign.cr, avgCheck: campaign.avgCheck)
                if !insights.isEmpty {
                    SectionHeader(title: "Insights", icon: "lightbulb.fill")
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(insights) { insight in
                            InsightRow(insight: insight)
                        }
                    }
                }

                // Navigation to detailed views
                SectionHeader(title: "Deep Analysis", icon: "magnifyingglass.circle.fill")

                NavigationLink {
                    ROASAnalysisView(
                        budget: campaign.budget, cpm: campaign.cpm,
                        ctr: campaign.ctr, cr: campaign.cr,
                        avgCheck: campaign.avgCheck, currency: c
                    )
                } label: {
                    analysisNavCard(
                        title: "ROI / ROAS Analysis",
                        subtitle: "Break-even, sensitivity, max CPC analysis",
                        icon: "chart.xyaxis.line",
                        color: AppColors.accentBlue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FunnelVisualizerView(
                        budget: campaign.budget, cpm: campaign.cpm,
                        ctr: campaign.ctr, cr: campaign.cr,
                        avgCheck: campaign.avgCheck, currency: c
                    )
                } label: {
                    analysisNavCard(
                        title: "Funnel Visualizer",
                        subtitle: "Visual conversion funnel with drop-off analysis",
                        icon: "chart.bar.doc.horizontal.fill",
                        color: AppColors.profitGreen
                    )
                }
                .buttonStyle(.plain)

                DisclaimerFooter()
            }
            .padding()
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(campaign.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        generateAndSharePDF()
                    } label: {
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ForwardPlannerView(editCampaign: campaign)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showExportSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    private func analysisNavCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .cardStyle()
    }

    private func generateAndSharePDF() {
        pdfData = PDFReportGenerator.generateReport(
            campaignName: campaign.name,
            budget: campaign.budget,
            cpm: campaign.cpm,
            ctr: campaign.ctr,
            cr: campaign.cr,
            avgCheck: campaign.avgCheck,
            currency: campaign.currency,
            platform: campaign.platform
        )
        if pdfData != nil {
            showExportSheet = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CampaignHubView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
