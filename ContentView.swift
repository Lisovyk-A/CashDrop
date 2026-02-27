import SwiftUI
import Combine
import ServiceManagement

// --- ПІДТРИМКА МОВ ---
enum AppLanguage: String, CaseIterable, Identifiable {
    case uk = "Українська"
    case en = "English"
    var id: String { self.rawValue }
}

struct ContentView: View {
    @EnvironmentObject var store: IncomeStore
    
    @State private var newName = ""
    @State private var newAmount = ""
    @State private var isAdding = false
    
    @State private var isPulsing = false
    
    @State private var editingIncomeId: UUID? = nil
    @State private var editingNameText: String = ""
    @State private var editingAmountText: String = ""
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("launchAtLogin") private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("appLanguage") private var language: AppLanguage = .uk // Зберігаємо обрану мову
    
    var mainBg: Color { colorScheme == .dark ? Color(red: 0.05, green: 0.07, blue: 0.06) : Color(red: 0.95, green: 0.96, blue: 0.97) }
    var cardBg: Color { colorScheme == .dark ? Color(red: 0.11, green: 0.13, blue: 0.12) : .white }
    var innerCardBg: Color { colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.03) }
    var accentColor: Color { colorScheme == .dark ? Color(red: 0.2, green: 0.85, blue: 0.4) : Color(red: 0.15, green: 0.75, blue: 0.3) }
    
    var textPrimary: Color { colorScheme == .dark ? .white : .black }
    var textSecondary: Color { colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5) }
    var strokeColor: Color { colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.05) }
    var fieldBg: Color { colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05) }
    
    // Словник перекладу
    func tr(_ key: String) -> String {
        let dict: [String: [AppLanguage: String]] = [
            "TOTAL_PLAN": [.uk: "ЗАГАЛЬНИЙ ПЛАН", .en: "TOTAL BALANCE"],
            "THIS_MONTH": [.uk: "ЗА МІСЯЦЬ", .en: "THIS MONTH"],
            "TODAY":      [.uk: "СЬОГОДНІ", .en: "TODAY"],
            "NO_INCOME":  [.uk: "Немає джерел доходу", .en: "No income sources"],
            "NAME":       [.uk: "Назва", .en: "Name"],
            "AMOUNT":     [.uk: "Сума", .en: "Amount"],
            "INCOME_NAME":[.uk: "Назва доходу", .en: "Income name"],
            "CURRENCY":   [.uk: "Оберіть валюту", .en: "Select currency"],
            "LANGUAGE":   [.uk: "Мова / Language", .en: "Language"],
            "AUTO_START": [.uk: "Автоматично запускати з Mac", .en: "Launch at login"]
        ]
        return dict[key]?[language] ?? key
    }
    
    var body: some View {
        ZStack {
            mainBg.ignoresSafeArea()
            
            if colorScheme == .dark {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -80, y: -150)
            }
            
            VStack(spacing: 0) {
                
                // --- 1. ГОЛОВНИЙ ДАШБОРД ---
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(tr("TOTAL_PLAN"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(textSecondary)
                            .tracking(2)
                        
                        Text("\(store.total.formatted(.number.precision(.fractionLength(2)))) \(store.selectedCurrency.symbol)")
                            .font(.system(size: 46, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accentColor, colorScheme == .dark ? Color(red: 0.6, green: 1.0, blue: 0.2) : accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(tr("THIS_MONTH"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(textSecondary)
                            
                            Text("\(store.selectedCurrency.symbol)\(store.earnedThisMonth.formatted(.number.precision(.fractionLength(2))))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(textPrimary)
                                .monospacedDigit()
                                .fixedSize(horizontal: true, vertical: false)
                                .contentTransition(.numericText(value: store.earnedThisMonth))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(innerCardBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text(tr("TODAY"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(textSecondary)
                                Spacer()
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 6, height: 6)
                                    .opacity(isPulsing ? 1.0 : 0.2)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                                    .onAppear { isPulsing = true }
                            }
                            
                            Text("\(store.selectedCurrency.symbol)\(store.earnedToday.formatted(.number.precision(.fractionLength(2))))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(accentColor)
                                .monospacedDigit()
                                .fixedSize(horizontal: true, vertical: false)
                                .contentTransition(.numericText(value: store.earnedToday))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(innerCardBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.05), radius: 20, x: 0, y: 10)
                .padding(16)
                
                // --- 2. СПИСОК ДОХОДІВ ---
                if store.incomes.isEmpty {
                    VStack {
                        Spacer()
                        Text(tr("NO_INCOME"))
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.incomes) { income in
                            HStack(spacing: 14) {
                                if editingIncomeId == income.id {
                                    TextField("", text: $editingNameText, prompt: Text(tr("NAME")).foregroundColor(textSecondary.opacity(0.5)))
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(textPrimary)
                                        .padding(.horizontal, 8)
                                        .frame(height: 36)
                                        .background(fieldBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    
                                    TextField("", text: $editingAmountText, prompt: Text(tr("AMOUNT")).foregroundColor(textSecondary.opacity(0.5)))
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal, 8)
                                        .frame(width: 80, height: 36)
                                        .background(fieldBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    
                                    Button {
                                        saveEdit(for: income)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(accentColor)
                                    }
                                    .buttonStyle(.plain)
                                    
                                } else {
                                    Text(income.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .onTapGesture { startEditing(income) }
                                    
                                    Text("\(income.amount.formatted(.number.precision(.fractionLength(0)))) \(store.selectedCurrency.symbol)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(textPrimary.opacity(0.8))
                                        .onTapGesture { startEditing(income) }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(cardBg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(strokeColor, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.02), radius: 5, x: 0, y: 2)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .onDelete { indexSet in
                            withAnimation(.spring()) { store.incomes.remove(atOffsets: indexSet) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                // --- 3. НИЖНЯ ПАНЕЛЬ ---
                VStack {
                    if isAdding {
                        HStack(spacing: 8) {
                            TextField("", text: $newName, prompt: Text(tr("INCOME_NAME")).foregroundColor(textSecondary))
                                .textFieldStyle(.plain)
                                .foregroundColor(textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .background(fieldBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            TextField("", text: $newAmount, prompt: Text(tr("AMOUNT")).foregroundColor(textSecondary))
                                .textFieldStyle(.plain)
                                .foregroundColor(textPrimary)
                                .padding(.horizontal, 12)
                                .frame(width: 75, height: 36)
                                .background(fieldBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            Button {
                                if let amount = Double(newAmount.replacingOccurrences(of: ",", with: ".")), !newName.isEmpty {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        store.incomes.append(Income(name: newName, amount: amount))
                                        isAdding = false
                                    }
                                    newName = ""
                                    newAmount = ""
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(mainBg)
                                    .frame(width: 36, height: 36)
                                    .background(accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isAdding = false
                                    newName = ""
                                    newAmount = ""
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(fieldBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                NSApplication.shared.terminate(nil)
                            } label: {
                                Image(systemName: "power")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(fieldBg, in: Circle())
                            }
                            .buttonStyle(.plain)
                            
                            Menu {
                                // МОВА
                                Section(tr("LANGUAGE")) {
                                    ForEach(AppLanguage.allCases) { lang in
                                        Button {
                                            language = lang
                                        } label: {
                                            Text("\(language == lang ? "✓ " : "")\(lang.rawValue)")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // ВАЛЮТА
                                Section(tr("CURRENCY")) {
                                    ForEach(AppCurrency.allCases, id: \.self) { currency in
                                        Button {
                                            store.selectedCurrency = currency
                                        } label: {
                                            Text("\(store.selectedCurrency == currency ? "✓ " : "")\(currency.symbol) \(currency.rawValue)")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // АВТОЗАПУСК
                                Toggle(tr("AUTO_START"), isOn: $launchAtLogin)
                                    .onChange(of: launchAtLogin) { _, newValue in
                                        do {
                                            if newValue {
                                                try SMAppService.mainApp.register()
                                            } else {
                                                try SMAppService.mainApp.unregister()
                                            }
                                        } catch {
                                            print("Автозапуск помилка: \(error)")
                                        }
                                    }
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(textSecondary)
                            }
                            .menuStyle(.borderlessButton)
                            .menuIndicator(.hidden)
                            .frame(width: 32, height: 32)
                            .background(fieldBg, in: Circle())
                            .contentShape(Circle())
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isAdding = true
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(mainBg)
                                    .frame(width: 32, height: 32)
                                    .background(accentColor, in: Circle())
                                    .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBg)
                .overlay(Rectangle().frame(height: 1).foregroundColor(strokeColor), alignment: .top)
            }
        }
        .frame(width: 360, height: 560)
    }
    
    func startEditing(_ income: Income) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            editingIncomeId = income.id
            editingNameText = income.name
            editingAmountText = String(format: "%.0f", income.amount)
        }
    }
    
    func saveEdit(for income: Income) {
        if let index = store.incomes.firstIndex(where: { $0.id == income.id }) {
            store.incomes[index].name = editingNameText
            if let newAmount = Double(editingAmountText.replacingOccurrences(of: ",", with: ".")) {
                store.incomes[index].amount = newAmount
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            editingIncomeId = nil
        }
    }
}
