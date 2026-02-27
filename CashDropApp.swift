import SwiftUI
import Combine

// --- 1. СПИСОК ВАЛЮТ ---
enum AppCurrency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case uah = "UAH"
    case gbp = "GBP"
    case pln = "PLN"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .uah: return "₴"
        case .gbp: return "£"
        case .pln: return "zł"
        }
    }
}

struct Income: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
}

class IncomeStore: ObservableObject {
    @Published var incomes: [Income] = [] {
        didSet {
            save()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                updateEarnings()
            }
        }
    }
    
    // Змінна для валюти
    @Published var selectedCurrency: AppCurrency = .eur {
        didSet { saveCurrency() }
    }
    
    @Published var earnedThisMonth: Double = 0.0
    @Published var earnedToday: Double = 0.0
    
    private var timer: AnyCancellable?
    
    var total: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    init() {
        load()
        loadCurrency() // Завантажуємо збережену валюту
        startLiveTicker()
    }
    
    func startLiveTicker() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                withAnimation(.linear(duration: 0.1)) {
                    self?.updateEarnings()
                }
            }
    }
    
    func updateEarnings() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return }
        let daysInMonth = Double(range.count)
        let dailyIncome = total / daysInMonth
        
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        let nanosecond = calendar.component(.nanosecond, from: now)
        
        let secondsInDay: Double = 86400
        let secondsPassed = Double(hour * 3600 + minute * 60 + second) + (Double(nanosecond) / 1_000_000_000.0)
        
        let currentProgress = secondsPassed / secondsInDay
        
        self.earnedToday = dailyIncome * currentProgress
        
        let currentDay = calendar.component(.day, from: now)
        let completedDays = Double(currentDay - 1)
        self.earnedThisMonth = (completedDays * dailyIncome) + self.earnedToday
    }
    
    // --- ЗБЕРЕЖЕННЯ ---
    func save() {
        if let data = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(data, forKey: "savedIncomesV2")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "savedIncomesV2"),
           let saved = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = saved
        }
    }
    
    func saveCurrency() {
        if let data = try? JSONEncoder().encode(selectedCurrency) {
            UserDefaults.standard.set(data, forKey: "savedCurrencyApp")
        }
    }
    
    func loadCurrency() {
        if let data = UserDefaults.standard.data(forKey: "savedCurrencyApp"),
           let saved = try? JSONDecoder().decode(AppCurrency.self, from: data) {
            selectedCurrency = saved
        }
    }
}

@main
struct CashDropApp: App {
    @StateObject private var store = IncomeStore()
    let neonGreen = Color(red: 0.2, green: 0.85, blue: 0.4)
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(neonGreen)
                
                // ВАЛЮТА В MENU BAR
                Text(String(format: "%@%.2f", store.selectedCurrency.symbol, store.earnedToday))
                    .monospacedDigit()
                    .foregroundColor(neonGreen)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.8), in: Capsule())
        }
        .menuBarExtraStyle(.window)
    }
}
