import SwiftUI
import PDFKit

// MARK: - PDF Report Generator

enum PDFReportGenerator {

    private static let whiteColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

    static func generateReport(
        campaignName: String,
        budget: Double,
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double,
        currency: String,
        platform: String?
    ) -> Data? {
        let metrics = MarketingEngine.calculate(
            budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck
        )
        let stages = MarketingEngine.funnelStages(
            budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck
        )

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return nil
        }

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        context.beginPage(mediaBox: &mediaBox)

        let bgColor = CGColor(red: 15/255, green: 17/255, blue: 23/255, alpha: 1)
        context.setFillColor(bgColor)
        context.fill(mediaBox)

        var y = pageHeight - margin

        // Title
        let titleFont = CTFontCreateWithName("SFProDisplay-Bold" as CFString, 24, nil)
        let titleStr = "Ad ROI Architect — Campaign Report"
        drawText(context: context, text: titleStr, x: margin, y: y, font: titleFont, color: whiteColor)
        y -= 36

        // Campaign Name
        let headFont = CTFontCreateWithName("SFProDisplay-Bold" as CFString, 18, nil)
        drawText(context: context, text: campaignName, x: margin, y: y, font: headFont,
                 color: CGColor(red: 0, green: 212/255, blue: 255/255, alpha: 1))
        y -= 28

        if let platform, !platform.isEmpty {
            let subFont = CTFontCreateWithName("SFProDisplay-Medium" as CFString, 12, nil)
            drawText(context: context, text: "Platform: \(platform)", x: margin, y: y, font: subFont,
                     color: CGColor(red: 160/255, green: 165/255, blue: 185/255, alpha: 1))
            y -= 22
        }

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateStr = "Generated: \(dateFormatter.string(from: Date()))"
        let captionFont = CTFontCreateWithName("SFProDisplay-Regular" as CFString, 10, nil)
        drawText(context: context, text: dateStr, x: margin, y: y, font: captionFont,
                 color: CGColor(red: 100/255, green: 105/255, blue: 125/255, alpha: 1))
        y -= 30

        // Divider
        drawLine(context: context, from: CGPoint(x: margin, y: y), to: CGPoint(x: pageWidth - margin, y: y),
                 color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.1))
        y -= 24

        // Input Parameters
        let sectionFont = CTFontCreateWithName("SFProDisplay-Bold" as CFString, 14, nil)
        let labelFont = CTFontCreateWithName("SFProDisplay-Medium" as CFString, 11, nil)
        let valueFont = CTFontCreateWithName("SFProDisplay-Bold" as CFString, 11, nil)
        let grayColor = CGColor(red: 160/255, green: 165/255, blue: 185/255, alpha: 1)

        drawText(context: context, text: "INPUT PARAMETERS", x: margin, y: y, font: sectionFont,
                 color: CGColor(red: 0, green: 212/255, blue: 255/255, alpha: 1))
        y -= 22

        let inputs: [(String, String)] = [
            ("Budget", AppFormatter.currencyFull(budget, symbol: currency)),
            ("CPM", AppFormatter.currencyFull(cpm, symbol: currency)),
            ("CTR", AppFormatter.percent(ctr)),
            ("Conversion Rate", AppFormatter.percent(cr)),
            ("Average Check", AppFormatter.currencyFull(avgCheck, symbol: currency))
        ]

        for (label, value) in inputs {
            drawText(context: context, text: label, x: margin, y: y, font: labelFont, color: grayColor)
            drawText(context: context, text: value, x: margin + 200, y: y, font: valueFont, color: whiteColor)
            y -= 18
        }

        y -= 16
        drawLine(context: context, from: CGPoint(x: margin, y: y), to: CGPoint(x: pageWidth - margin, y: y),
                 color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.1))
        y -= 24

        // Calculated Metrics
        drawText(context: context, text: "CALCULATED METRICS", x: margin, y: y, font: sectionFont,
                 color: CGColor(red: 0, green: 212/255, blue: 255/255, alpha: 1))
        y -= 22

        let greenColor = CGColor(red: 0, green: 230/255, blue: 118/255, alpha: 1)
        let redColor = CGColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 1)

        let calculated: [(String, String, CGColor)] = [
            ("Impressions", AppFormatter.integer(metrics.impressions), whiteColor),
            ("Clicks", AppFormatter.integer(metrics.clicks), whiteColor),
            ("CPC", AppFormatter.currencyFull(metrics.cpc, symbol: currency), whiteColor),
            ("Leads / Sales", AppFormatter.integer(metrics.leads), whiteColor),
            ("CPL / CAC", AppFormatter.currencyFull(metrics.cpl, symbol: currency), whiteColor),
            ("Revenue", AppFormatter.currencyFull(metrics.revenue, symbol: currency), whiteColor),
            ("Profit", AppFormatter.currencyFull(metrics.profit, symbol: currency), metrics.isProfitable ? greenColor : redColor),
            ("ROAS", AppFormatter.roas(metrics.roas), metrics.roas >= 1 ? greenColor : redColor),
            ("ROI", AppFormatter.percent(metrics.roi), metrics.roi >= 0 ? greenColor : redColor),
            ("Max CPC (break-even)", AppFormatter.currencyFull(metrics.maxCPC, symbol: currency), whiteColor)
        ]

        for (label, value, color) in calculated {
            drawText(context: context, text: label, x: margin, y: y, font: labelFont, color: grayColor)
            drawText(context: context, text: value, x: margin + 200, y: y, font: valueFont, color: color)
            y -= 18
        }

        y -= 16
        drawLine(context: context, from: CGPoint(x: margin, y: y), to: CGPoint(x: pageWidth - margin, y: y),
                 color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.1))
        y -= 24

        // Funnel
        drawText(context: context, text: "CONVERSION FUNNEL", x: margin, y: y, font: sectionFont,
                 color: CGColor(red: 0, green: 212/255, blue: 255/255, alpha: 1))
        y -= 22

        let maxCount = stages.first?.count ?? 1
        let barMaxWidth: CGFloat = pageWidth - margin * 2 - 120

        for stage in stages {
            drawText(context: context, text: stage.name, x: margin, y: y, font: labelFont, color: grayColor)
            drawText(context: context, text: AppFormatter.integer(stage.count), x: pageWidth - margin - 80, y: y, font: valueFont, color: whiteColor)

            y -= 14
            let barWidth = maxCount > 0 ? barMaxWidth * (stage.count / maxCount) : 0
            let barRect = CGRect(x: margin, y: y - 10, width: barWidth, height: 12)
            let barColor = CGColor(red: 0, green: 212/255, blue: 255/255, alpha: 0.6)
            context.setFillColor(barColor)
            let path = CGPath(roundedRect: barRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            context.addPath(path)
            context.fillPath()
            y -= 24
        }

        y -= 16

        // Disclaimer
        let disclaimerFont = CTFontCreateWithName("SFProDisplay-Regular" as CFString, 7, nil)
        drawText(context: context, text: AppConstants.disclaimer, x: margin, y: margin + 10, font: disclaimerFont, color: grayColor)

        context.endPage()
        context.closePDF()

        return pdfData as Data
    }

    // MARK: Helpers

    private static func drawText(
        context: CGContext,
        text: String,
        x: CGFloat,
        y: CGFloat,
        font: CTFont,
        color: CGColor
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrStr)

        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func drawLine(
        context: CGContext,
        from: CGPoint,
        to: CGPoint,
        color: CGColor,
        width: CGFloat = 0.5
    ) {
        context.setStrokeColor(color)
        context.setLineWidth(width)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }
}
