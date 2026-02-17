import SwiftUI

// MARK: - Color Palette

enum AppColors {
    static let backgroundPrimary = Color(red: 15/255, green: 17/255, blue: 23/255)     // #0F1117
    static let backgroundSecondary = Color(red: 26/255, green: 29/255, blue: 39/255)   // #1A1D27
    static let backgroundCard = Color(red: 22/255, green: 25/255, blue: 35/255)        // #161923
    static let backgroundInput = Color(red: 30/255, green: 34/255, blue: 46/255)       // #1E222E

    static let accentBlue = Color(red: 0/255, green: 212/255, blue: 255/255)           // #00D4FF
    static let profitGreen = Color(red: 0/255, green: 230/255, blue: 118/255)          // #00E676
    static let lossRed = Color(red: 255/255, green: 82/255, blue: 82/255)              // #FF5252
    static let warningYellow = Color(red: 255/255, green: 214/255, blue: 0/255)        // #FFD600

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 160/255, green: 165/255, blue: 185/255)      // #A0A5B9
    static let textTertiary = Color(red: 100/255, green: 105/255, blue: 125/255)       // #64697D

    static let divider = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.05)

    static func metricColor(for value: Double, threshold: Double = 0) -> Color {
        value >= threshold ? profitGreen : lossRed
    }

    static func roasColor(_ roas: Double) -> Color {
        if roas >= 3.0 { return profitGreen }
        if roas >= 1.0 { return warningYellow }
        return lossRed
    }
}

// MARK: - Typography

enum AppTypography {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let headline = Font.system(size: 22, weight: .bold, design: .default)
    static let title = Font.system(size: 18, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .medium, design: .default)
    static let caption = Font.system(size: 13, weight: .medium, design: .default)
    static let footnote = Font.system(size: 11, weight: .regular, design: .default)

    static let kpiLarge = Font.system(size: 40, weight: .bold, design: .monospaced)
    static let kpiMedium = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let kpiSmall = Font.system(size: 20, weight: .bold, design: .monospaced)
    static let metricValue = Font.system(size: 16, weight: .semibold, design: .monospaced)
}

// MARK: - Spacing & Sizing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum AppCorners {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 24
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = AppSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.large, style: .continuous)
                    .fill(AppColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.large, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
    }
}

struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.small, style: .continuous)
                    .fill(AppColors.backgroundInput)
            )
    }
}

struct GlowButtonStyle: ButtonStyle {
    var color: Color = AppColors.accentBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.title)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.medium, style: .continuous)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 4 : 12, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.body)
            .foregroundColor(AppColors.accentBlue)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.medium, style: .continuous)
                    .stroke(AppColors.accentBlue.opacity(0.5), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func inputStyle() -> some View {
        modifier(InputFieldModifier())
    }

    func screenBackground() -> some View {
        self.background(AppColors.backgroundPrimary.ignoresSafeArea())
    }
}

// MARK: - Number Formatting

enum AppFormatter {
    static func currency(_ value: Double, symbol: String = "$") -> String {
        if abs(value) >= 1_000_000 {
            return "\(symbol)\(String(format: "%.1fM", value / 1_000_000))"
        } else if abs(value) >= 1_000 {
            return "\(symbol)\(String(format: "%.1fK", value / 1_000))"
        } else {
            return "\(symbol)\(String(format: "%.2f", value))"
        }
    }

    static func currencyFull(_ value: Double, symbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(symbol)\(formatted)"
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }

    static func decimal(_ value: Double, places: Int = 2) -> String {
        String(format: "%.\(places)f", value)
    }

    static func integer(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    static func roas(_ value: Double) -> String {
        String(format: "%.2fx", value)
    }
}

// MARK: - Disclaimer

enum AppConstants {
    static let disclaimer = "This is a private personal marketing simulation tool for educational and planning purposes. Not financial advice or professional advertising software."

    static let appVersion = "1.0.0"

    static let defaultCurrencies = ["$", "€", "£", "¥", "₽", "₴", "₹", "R$", "A$", "C$"]

    static let platformNames = ["Facebook Ads", "Google Ads", "TikTok Ads", "Instagram Ads", "LinkedIn Ads", "Twitter/X Ads", "Custom"]
}
