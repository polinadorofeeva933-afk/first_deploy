import SwiftUI

// MARK: - Glossary View

struct GlossaryView: View {
    @State private var searchText = ""
    @State private var expandedTermID: String?

    private var filteredTerms: [GlossaryTerm] {
        if searchText.isEmpty { return GlossaryData.allTerms }
        return GlossaryData.allTerms.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.abbreviation.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedTerms: [(String, [GlossaryTerm])] {
        let grouped = Dictionary(grouping: filteredTerms) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Search bar
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textTertiary)
                            TextField("Search metrics, formulas...", text: $searchText)
                                .foregroundColor(AppColors.textPrimary)
                                .autocorrectionDisabled()
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                                .fill(AppColors.backgroundInput)
                        )

                        // Terms
                        ForEach(groupedTerms, id: \.0) { category, terms in
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text(category)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.accentBlue)
                                    .textCase(.uppercase)
                                    .padding(.top, AppSpacing.sm)

                                ForEach(terms) { term in
                                    glossaryCard(term)
                                }
                            }
                        }

                        if filteredTerms.isEmpty {
                            VStack(spacing: AppSpacing.md) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("No results found")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.top, 60)
                        }

                        DisclaimerFooter()
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Glossary")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Glossary Card

    private func glossaryCard(_ term: GlossaryTerm) -> some View {
        let isExpanded = expandedTermID == term.id

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedTermID = isExpanded ? nil : term.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(term.abbreviation)
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        Text(term.term)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Divider().background(AppColors.divider)

                    Text(term.definition)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let formula = term.formula {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "function")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accentBlue)
                            Text(formula)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(AppColors.accentBlue)
                        }
                        .padding(AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppColors.accentBlue.opacity(0.08))
                        )
                    }

                    if let example = term.example {
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.warningYellow)
                            Text(example)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }
}

// MARK: - Glossary Data

struct GlossaryTerm: Identifiable {
    let id: String
    let abbreviation: String
    let term: String
    let definition: String
    let formula: String?
    let example: String?
    let category: String
}

enum GlossaryData {
    static let allTerms: [GlossaryTerm] = [
        GlossaryTerm(
            id: "cpm", abbreviation: "CPM",
            term: "Cost Per Mille",
            definition: "The cost an advertiser pays for one thousand impressions (views) of their advertisement. It is a standard metric for measuring the cost-efficiency of ad reach.",
            formula: "CPM = (Total Ad Spend / Impressions) × 1000",
            example: "If you spend $500 and get 100,000 impressions, your CPM is $5.00.",
            category: "Cost Metrics"
        ),
        GlossaryTerm(
            id: "cpc", abbreviation: "CPC",
            term: "Cost Per Click",
            definition: "The average amount an advertiser pays each time a user clicks on their ad. Lower CPC indicates more efficient ad spending for driving traffic.",
            formula: "CPC = Total Ad Spend / Number of Clicks",
            example: "If you spend $1,000 and get 500 clicks, your CPC is $2.00.",
            category: "Cost Metrics"
        ),
        GlossaryTerm(
            id: "cpl", abbreviation: "CPL",
            term: "Cost Per Lead",
            definition: "The average cost of acquiring a single lead (potential customer who has shown interest). This metric helps evaluate the efficiency of lead generation campaigns.",
            formula: "CPL = Total Ad Spend / Number of Leads",
            example: "If you spend $2,000 and generate 40 leads, your CPL is $50.",
            category: "Cost Metrics"
        ),
        GlossaryTerm(
            id: "cac", abbreviation: "CAC",
            term: "Customer Acquisition Cost",
            definition: "The total cost of acquiring a new paying customer, including all marketing and sales expenses. In simplified models, CAC equals CPL when every lead converts to a sale.",
            formula: "CAC = Total Marketing Cost / New Customers Acquired",
            example: "If total marketing spend is $10,000 and you acquire 50 customers, CAC is $200.",
            category: "Cost Metrics"
        ),
        GlossaryTerm(
            id: "ctr", abbreviation: "CTR",
            term: "Click-Through Rate",
            definition: "The percentage of users who click on an ad after seeing it. Higher CTR indicates more engaging and relevant ad creative. Industry benchmarks vary by platform and vertical.",
            formula: "CTR = (Clicks / Impressions) × 100%",
            example: "If your ad gets 250 clicks from 10,000 impressions, CTR is 2.5%.",
            category: "Conversion Metrics"
        ),
        GlossaryTerm(
            id: "cr", abbreviation: "CR",
            term: "Conversion Rate",
            definition: "The percentage of visitors who complete a desired action (purchase, sign-up, etc.). Higher CR means your landing page and offer are more effective at converting traffic.",
            formula: "CR = (Conversions / Total Visitors) × 100%",
            example: "If 30 out of 1,000 visitors make a purchase, CR is 3.0%.",
            category: "Conversion Metrics"
        ),
        GlossaryTerm(
            id: "roas", abbreviation: "ROAS",
            term: "Return On Ad Spend",
            definition: "The revenue generated for every dollar spent on advertising. ROAS of 1.0x means you break even; above 1.0x means profit; below 1.0x means loss. Most businesses aim for 3x+ ROAS.",
            formula: "ROAS = Revenue / Ad Spend",
            example: "If you spend $5,000 on ads and generate $15,000 in revenue, ROAS is 3.0x.",
            category: "Profitability Metrics"
        ),
        GlossaryTerm(
            id: "roi", abbreviation: "ROI",
            term: "Return On Investment",
            definition: "The percentage return on your advertising investment. Positive ROI means you're making more than you spend; negative ROI means you're losing money.",
            formula: "ROI = ((Revenue - Cost) / Cost) × 100%",
            example: "If you invest $10,000 and earn $25,000 in revenue, ROI is 150%.",
            category: "Profitability Metrics"
        ),
        GlossaryTerm(
            id: "romi", abbreviation: "ROMI",
            term: "Return On Marketing Investment",
            definition: "Similar to ROI but specifically focused on marketing expenditures. It considers only the profit attributable to marketing activities divided by the marketing cost.",
            formula: "ROMI = (Gross Profit from Marketing - Marketing Cost) / Marketing Cost × 100%",
            example: "If marketing generates $50,000 profit on $20,000 spend, ROMI is 150%.",
            category: "Profitability Metrics"
        ),
        GlossaryTerm(
            id: "ltv", abbreviation: "LTV",
            term: "Lifetime Value",
            definition: "The total revenue a business can expect from a single customer account throughout their entire relationship. LTV helps determine how much to invest in acquiring each customer.",
            formula: "LTV = Average Check × Purchase Frequency × Customer Lifespan",
            example: "If a customer spends $100/month for 24 months, LTV is $2,400.",
            category: "Customer Metrics"
        ),
        GlossaryTerm(
            id: "ltv_cac", abbreviation: "LTV:CAC",
            term: "LTV to CAC Ratio",
            definition: "The ratio of customer lifetime value to acquisition cost. A ratio of 3:1 is considered healthy — you earn $3 for every $1 spent acquiring the customer.",
            formula: "LTV:CAC = Customer Lifetime Value / Customer Acquisition Cost",
            example: "If LTV is $900 and CAC is $300, the ratio is 3:1 — a healthy benchmark.",
            category: "Customer Metrics"
        ),
        GlossaryTerm(
            id: "maxcpc", abbreviation: "Max CPC",
            term: "Maximum Cost Per Click",
            definition: "The highest price per click at which your campaign remains profitable. If actual CPC exceeds Max CPC, the campaign loses money on every click.",
            formula: "Max CPC = Average Check × (CR / 100)",
            example: "If average check is $150 and CR is 3%, Max CPC is $4.50.",
            category: "Optimization Metrics"
        ),
        GlossaryTerm(
            id: "breakeven", abbreviation: "BEP",
            term: "Break-Even Point",
            definition: "The point at which total revenue equals total cost — neither profit nor loss. Understanding BEP helps determine minimum performance requirements for campaign viability.",
            formula: "Break-Even: Revenue = Total Ad Spend (ROAS = 1.0x)",
            example: "If your ROAS is exactly 1.0x, you're at break-even — no profit, no loss.",
            category: "Optimization Metrics"
        ),
        GlossaryTerm(
            id: "impressions", abbreviation: "IMP",
            term: "Impressions",
            definition: "The total number of times an ad is displayed to users. One user may generate multiple impressions. Impressions measure reach and ad delivery volume.",
            formula: "Impressions = (Budget / CPM) × 1000",
            example: "With a $5,000 budget and $10 CPM, you'll get 500,000 impressions.",
            category: "Funnel Metrics"
        ),
        GlossaryTerm(
            id: "mediaplanning", abbreviation: "MP",
            term: "Media Planning",
            definition: "The strategic process of selecting the optimal combination of media channels, ad formats, targeting, and budget allocation to achieve advertising objectives efficiently.",
            formula: nil,
            example: "A media plan might allocate 60% to Facebook, 30% to Google, and 10% to TikTok based on target audience behavior.",
            category: "Strategy"
        ),
        GlossaryTerm(
            id: "funnel", abbreviation: "—",
            term: "Marketing Funnel",
            definition: "A model representing the customer journey from initial awareness through interest and consideration to final conversion. Each stage has fewer people, creating a funnel shape.",
            formula: nil,
            example: "100,000 impressions → 2,500 clicks (2.5% CTR) → 75 leads (3% CR) → sales.",
            category: "Strategy"
        ),
        GlossaryTerm(
            id: "abtesting", abbreviation: "A/B",
            term: "A/B Testing",
            definition: "A method of comparing two variants of an ad, landing page, or campaign to determine which performs better. Only one variable should change between variants for meaningful results.",
            formula: nil,
            example: "Test two headlines: variant A gets 2.1% CTR, variant B gets 3.4% CTR — B wins.",
            category: "Strategy"
        )
    ]
}

#Preview {
    GlossaryView()
}
