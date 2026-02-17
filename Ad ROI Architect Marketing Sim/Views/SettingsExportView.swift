import SwiftUI
import CoreData

// MARK: - Settings & Export View

struct SettingsExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CampaignEntity.updatedAt, ascending: false)],
        animation: .easeInOut
    )
    private var campaigns: FetchedResults<CampaignEntity>

    @AppStorage("selectedCurrency") private var selectedCurrency = "$"
    @AppStorage("defaultPlatform") private var defaultPlatform = ""

    @State private var showExportSheet = false
    @State private var exportPDFData: Data?
    @State private var selectedCampaignForExport: CampaignEntity?
    @State private var showDeleteAllAlert = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Currency
                        currencySection

                        // Default Platform
                        platformSection

                        // Export
                        exportSection

                        // Data Management
                        dataSection

                        // About
                        aboutSection

                        DisclaimerFooter()
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showExportSheet) {
                if let data = exportPDFData {
                    ShareSheet(items: [data])
                }
            }
            .alert("Delete All Campaigns", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllCampaigns()
                }
            } message: {
                Text("This will permanently delete all saved campaigns and scenarios. This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Currency Section

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Default Currency", icon: "dollarsign.circle")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: AppSpacing.sm) {
                ForEach(AppConstants.defaultCurrencies, id: \.self) { curr in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCurrency = curr
                        }
                    } label: {
                        Text(curr)
                            .font(AppTypography.title)
                            .foregroundColor(selectedCurrency == curr ? .white : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                                    .fill(selectedCurrency == curr ? AppColors.accentBlue : AppColors.backgroundInput)
                            )
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: Platform Section

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Default Platform", subtitle: "Pre-selected for new campaigns", icon: "globe")

            VStack(spacing: AppSpacing.sm) {
                ForEach([""] + AppConstants.platformNames, id: \.self) { platform in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            defaultPlatform = platform
                        }
                    } label: {
                        HStack {
                            Text(platform.isEmpty ? "None" : platform)
                                .font(AppTypography.body)
                                .foregroundColor(defaultPlatform == platform ? .white : AppColors.textSecondary)
                            Spacer()
                            if defaultPlatform == platform {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.accentBlue)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                                .fill(defaultPlatform == platform ? AppColors.accentBlue.opacity(0.15) : AppColors.backgroundInput)
                        )
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Export Campaign Report", subtitle: "Generate a PDF report for any saved campaign", icon: "doc.richtext")

            if campaigns.isEmpty {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(AppColors.textTertiary)
                    Text("No campaigns to export. Create a campaign first.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .cardStyle()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(campaigns, id: \.objectID) { campaign in
                        Button {
                            exportCampaign(campaign)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(campaign.name)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(AppFormatter.currency(campaign.budget, symbol: campaign.currency))
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                                    .fill(AppColors.backgroundInput)
                            )
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Data Management", icon: "externaldrive")

            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(AppColors.textTertiary)
                    Text("Saved Campaigns")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(campaigns.count)")
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.accentBlue)
                }
                .padding(.vertical, AppSpacing.xs)

                Divider().background(AppColors.divider)

                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete All Campaigns")
                            .font(AppTypography.body)
                        Spacer()
                    }
                    .foregroundColor(campaigns.isEmpty ? AppColors.textTertiary : AppColors.lossRed)
                }
                .disabled(campaigns.isEmpty)
            }
            .cardStyle()
        }
    }

    // MARK: About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "About", icon: "info.circle")

            VStack(spacing: AppSpacing.md) {
                HStack {
                    Text("App")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("Ad ROI Architect")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }

                HStack {
                    Text("Version")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(AppConstants.appVersion)
                        .font(AppTypography.metricValue)
                        .foregroundColor(AppColors.textTertiary)
                }

                HStack {
                    Text("Data Storage")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("Local Only (Core Data)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                HStack {
                    Text("Network Access")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("None — 100% Offline")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.profitGreen)
                }

                HStack {
                    Text("Privacy")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("No data collected")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.profitGreen)
                }

                Divider().background(AppColors.divider)

                Text(AppConstants.disclaimer)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.leading)
            }
            .cardStyle()
        }
    }

    // MARK: Actions

    private func exportCampaign(_ campaign: CampaignEntity) {
        exportPDFData = PDFReportGenerator.generateReport(
            campaignName: campaign.name,
            budget: campaign.budget,
            cpm: campaign.cpm,
            ctr: campaign.ctr,
            cr: campaign.cr,
            avgCheck: campaign.avgCheck,
            currency: campaign.currency,
            platform: campaign.platform
        )
        if exportPDFData != nil {
            showExportSheet = true
        }
    }

    private func deleteAllCampaigns() {
        for campaign in campaigns {
            viewContext.delete(campaign)
        }
        PersistenceController.shared.save()
    }
}

#Preview {
    SettingsExportView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
