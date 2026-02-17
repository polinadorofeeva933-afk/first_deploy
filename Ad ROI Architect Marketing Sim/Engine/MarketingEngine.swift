import Foundation

// MARK: - Campaign Metrics Result

struct CampaignMetrics: Equatable, Sendable {
    let impressions: Double
    let clicks: Double
    let cpc: Double
    let leads: Double
    let cpl: Double
    let revenue: Double
    let profit: Double
    let roas: Double
    let roi: Double
    let cac: Double
    let maxCPC: Double
    let breakEvenBudget: Double
    let costPerImpression: Double
    let clickThroughValue: Double
    let conversionValue: Double
    let wastedSpend: Double

    var isProfitable: Bool { profit > 0 }
    var isViable: Bool { roas >= 1.0 }
    var roasCategory: ROASCategory {
        if roas >= 4.0 { return .excellent }
        if roas >= 2.0 { return .good }
        if roas >= 1.0 { return .breakEven }
        return .losing
    }

    enum ROASCategory: String {
        case excellent = "Excellent"
        case good = "Good"
        case breakEven = "Break-even"
        case losing = "Losing"

        var description: String {
            switch self {
            case .excellent: return "Campaign is highly profitable"
            case .good: return "Campaign is profitable"
            case .breakEven: return "Campaign is barely covering costs"
            case .losing: return "Campaign is losing money"
            }
        }
    }

    static let zero = CampaignMetrics(
        impressions: 0, clicks: 0, cpc: 0, leads: 0, cpl: 0,
        revenue: 0, profit: 0, roas: 0, roi: 0, cac: 0,
        maxCPC: 0, breakEvenBudget: 0, costPerImpression: 0,
        clickThroughValue: 0, conversionValue: 0, wastedSpend: 0
    )
}

// MARK: - Reverse Calculation Result

struct ReverseResult: Equatable, Sendable {
    let requiredBudget: Double
    let requiredImpressions: Double
    let requiredClicks: Double
    let requiredLeads: Double
    let totalRevenue: Double
    let effectiveROAS: Double
    let effectiveROI: Double
    let isAchievable: Bool
    let reason: String

    static let notAchievable = ReverseResult(
        requiredBudget: 0, requiredImpressions: 0, requiredClicks: 0,
        requiredLeads: 0, totalRevenue: 0, effectiveROAS: 0,
        effectiveROI: 0, isAchievable: false,
        reason: "Not achievable with current parameters. Increase CR or Average Check, or decrease CPM."
    )
}

// MARK: - Funnel Stage

struct FunnelStage: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let count: Double
    let cost: Double
    let dropOff: Double
    let percentage: Double
}

// MARK: - Marketing Engine

enum MarketingEngine {

    // MARK: Forward Calculation

    static func calculate(
        budget: Double,
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double
    ) -> CampaignMetrics {
        guard budget > 0, cpm > 0, ctr > 0, cr > 0, avgCheck > 0 else {
            return .zero
        }

        let impressions = (budget / cpm) * 1000.0
        let clicks = impressions * (ctr / 100.0)
        let cpc = clicks > 0 ? budget / clicks : 0
        let leads = clicks * (cr / 100.0)
        let cpl = leads > 0 ? budget / leads : 0
        let revenue = leads * avgCheck
        let profit = revenue - budget
        let roas = budget > 0 ? revenue / budget : 0
        let roi = budget > 0 ? ((revenue - budget) / budget) * 100.0 : 0
        let cac = cpl
        let maxCPC = avgCheck * (cr / 100.0)
        let costPerImpression = impressions > 0 ? budget / impressions : 0

        let clickThroughValue = clicks > 0 ? revenue / clicks : 0
        let conversionValue = leads > 0 ? revenue / leads : 0
        let wastedSpend = max(0, budget - revenue)

        let revenuePerUnit = ctr / 100.0 * cr / 100.0 * avgCheck
        let costPerUnit = cpm / 1000.0
        let breakEvenBudget: Double
        if revenuePerUnit > costPerUnit {
            breakEvenBudget = 0
        } else {
            breakEvenBudget = budget
        }

        return CampaignMetrics(
            impressions: impressions,
            clicks: clicks,
            cpc: cpc,
            leads: leads,
            cpl: cpl,
            revenue: revenue,
            profit: profit,
            roas: roas,
            roi: roi,
            cac: cac,
            maxCPC: maxCPC,
            breakEvenBudget: breakEvenBudget,
            costPerImpression: costPerImpression,
            clickThroughValue: clickThroughValue,
            conversionValue: conversionValue,
            wastedSpend: wastedSpend
        )
    }

    // MARK: Reverse Calculation

    static func reverseCalculate(
        desiredProfit: Double,
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double
    ) -> ReverseResult {
        guard cpm > 0, ctr > 0, cr > 0, avgCheck > 0, desiredProfit > 0 else {
            return .notAchievable
        }

        let k = (ctr / 100.0) * (cr / 100.0) * (1000.0 / cpm) * avgCheck

        guard k > 1 else {
            return ReverseResult(
                requiredBudget: 0,
                requiredImpressions: 0,
                requiredClicks: 0,
                requiredLeads: 0,
                totalRevenue: 0,
                effectiveROAS: k,
                effectiveROI: (k - 1) * 100,
                isAchievable: false,
                reason: "Revenue per dollar spent (\(String(format: "%.2f", k))x) is below 1.0x. Improve CTR, CR, or Average Check to make profit possible."
            )
        }

        let requiredBudget = desiredProfit / (k - 1)
        let requiredImpressions = (requiredBudget / cpm) * 1000.0
        let requiredClicks = requiredImpressions * (ctr / 100.0)
        let requiredLeads = requiredClicks * (cr / 100.0)
        let totalRevenue = requiredLeads * avgCheck
        let effectiveROAS = k
        let effectiveROI = (k - 1) * 100

        return ReverseResult(
            requiredBudget: requiredBudget,
            requiredImpressions: requiredImpressions,
            requiredClicks: requiredClicks,
            requiredLeads: requiredLeads,
            totalRevenue: totalRevenue,
            effectiveROAS: effectiveROAS,
            effectiveROI: effectiveROI,
            isAchievable: true,
            reason: "Achievable. ROAS: \(String(format: "%.2f", effectiveROAS))x"
        )
    }

    // MARK: Funnel Stages

    static func funnelStages(
        budget: Double,
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double
    ) -> [FunnelStage] {
        guard budget > 0, cpm > 0 else { return [] }

        let impressions = (budget / cpm) * 1000.0
        let clicks = impressions * (ctr / 100.0)
        let leads = clicks * (cr / 100.0)
        let sales = leads

        let clickDropOff = impressions > 0 ? ((impressions - clicks) / impressions) * 100 : 0
        let leadDropOff = clicks > 0 ? ((clicks - leads) / clicks) * 100 : 0

        return [
            FunnelStage(
                name: "Impressions",
                count: impressions,
                cost: budget,
                dropOff: 0,
                percentage: 100
            ),
            FunnelStage(
                name: "Clicks",
                count: clicks,
                cost: clicks > 0 ? budget / clicks * clicks : 0,
                dropOff: clickDropOff,
                percentage: impressions > 0 ? (clicks / impressions) * 100 : 0
            ),
            FunnelStage(
                name: "Leads",
                count: leads,
                cost: leads > 0 ? budget / leads * leads : 0,
                dropOff: leadDropOff,
                percentage: impressions > 0 ? (leads / impressions) * 100 : 0
            ),
            FunnelStage(
                name: "Sales",
                count: sales,
                cost: sales * avgCheck,
                dropOff: 0,
                percentage: impressions > 0 ? (sales / impressions) * 100 : 0
            )
        ]
    }

    // MARK: Break-even Analysis

    static func breakEvenPoints(
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double,
        maxBudget: Double
    ) -> [(budget: Double, profit: Double)] {
        guard maxBudget > 0 else { return [] }
        let steps = 20
        let stepSize = maxBudget / Double(steps)
        var points: [(budget: Double, profit: Double)] = []

        for i in 0...steps {
            let b = stepSize * Double(i)
            let metrics = calculate(budget: b, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck)
            points.append((budget: b, profit: metrics.profit))
        }
        return points
    }

    // MARK: Sensitivity Analysis

    static func sensitivityCTR(
        budget: Double,
        cpm: Double,
        baseCTR: Double,
        cr: Double,
        avgCheck: Double,
        range: ClosedRange<Double> = 0.5...5.0,
        steps: Int = 10
    ) -> [(ctr: Double, roas: Double)] {
        let step = (range.upperBound - range.lowerBound) / Double(steps)
        return (0...steps).map { i in
            let ctr = range.lowerBound + step * Double(i)
            let metrics = calculate(budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck)
            return (ctr: ctr, roas: metrics.roas)
        }
    }

    // MARK: Advisory Insights

    static func insights(for metrics: CampaignMetrics, ctr: Double, cr: Double, avgCheck: Double) -> [MarketingInsight] {
        var result: [MarketingInsight] = []

        if metrics.cpc > metrics.maxCPC {
            result.append(MarketingInsight(
                severity: .critical,
                message: "CPC (\(AppFormatter.currency(metrics.cpc))) exceeds max profitable CPC (\(AppFormatter.currency(metrics.maxCPC))). Lower CPM or increase CR."
            ))
        }

        if metrics.roas < 1.0 {
            result.append(MarketingInsight(
                severity: .critical,
                message: "ROAS is below 1.0x — campaign loses money on every dollar spent."
            ))
        } else if metrics.roas < 2.0 {
            result.append(MarketingInsight(
                severity: .warning,
                message: "ROAS is between 1–2x. Profitable but thin margins. Consider optimization."
            ))
        }

        if ctr < 1.0 {
            result.append(MarketingInsight(
                severity: .warning,
                message: "CTR below 1% is typical but leaves room for creative optimization."
            ))
        }

        if cr < 2.0 {
            result.append(MarketingInsight(
                severity: .info,
                message: "CR below 2% is common. A/B test landing pages to improve conversion."
            ))
        }

        if metrics.cpl > avgCheck {
            result.append(MarketingInsight(
                severity: .critical,
                message: "Cost per lead (\(AppFormatter.currency(metrics.cpl))) exceeds average check (\(AppFormatter.currency(avgCheck))). Each lead costs more than it generates."
            ))
        }

        if metrics.isProfitable && metrics.roas >= 3.0 {
            result.append(MarketingInsight(
                severity: .positive,
                message: "Strong ROAS of \(AppFormatter.roas(metrics.roas)). Consider scaling budget to maximize returns."
            ))
        }

        return result
    }
}

// MARK: - Marketing Insight

struct MarketingInsight: Identifiable {
    let id = UUID()
    let severity: Severity
    let message: String

    enum Severity {
        case critical, warning, info, positive

        var iconName: String {
            switch self {
            case .critical: return "exclamationmark.octagon.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .positive: return "checkmark.circle.fill"
            }
        }
    }
}
