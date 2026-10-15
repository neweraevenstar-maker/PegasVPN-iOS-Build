
import SwiftUI

struct VPNWhitelistView: View {
    @State private var whitelist = VPNWhitelist.load()
    @State private var newCIDR = ""
    @State private var showInvalid = false

    var body: some View {
        Form {
            Section {
                Text("Укажите IP-адрес или подсеть, которые должны обходить VPN.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Например: 192.168.1.0/24", text: $newCIDR)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.numbersAndPunctuation)

                    Button("Добавить") {
                        if whitelist.add(newCIDR) {
                            whitelist.save()
                            newCIDR = ""
                        } else {
                            showInvalid = true
                        }
                    }
                    .disabled(newCIDR.isEmpty)
                }
            } header: {
                Text("Исключения из VPN")
            }

            Section("Сохранённые подсети") {
                if whitelist.excludedIPv4.isEmpty {
                    Text("Исключений пока нет")
                        .foregroundStyle(.secondary)
                }

                ForEach(whitelist.excludedIPv4, id: \.self) { cidr in
                    Text(cidr)
                        .font(.system(.body, design: .monospaced))
                }
                .onDelete { offsets in
                    whitelist.remove(at: offsets)
                    whitelist.save()
                }
            }

            Section {
                Text("Изменения применяются при следующем подключении. Выключите Kill Switch, чтобы использовать исключения IPv4. Режим «Россия — белые списки» пока не подключён; это отдельная будущая функция.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Исключения IPv4")
            .pegasPremiumScreen()
        .alert("Неверный адрес", isPresented: $showInvalid) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Введите IPv4-подсеть, например 10.0.0.0/8. Нельзя исключить весь интернет (0.0.0.0/0). Максимум 32 подсети.")
        }
    }
}
