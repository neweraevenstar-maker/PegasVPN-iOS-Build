
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
                Text("Изменения маршрутов применяются при следующем подключении VPN. Исключения по названиям приложений недоступны в этом режиме iOS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Белые списки")
        .alert("Неверный адрес", isPresented: $showInvalid) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Введите корректную IPv4-подсеть, например 10.0.0.0/8.")
        }
    }
}
