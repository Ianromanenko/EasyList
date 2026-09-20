import SwiftUI

/// Кнопка ADJUST: всё, что настраивается. Держим в одном списке,
/// чтобы не плодить экраны — на часах это дороже всего.
struct SettingsView: View {
    var engine: FaceEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("ДИСПЛЕЙ") {
                Picker("Тема", selection: Binding(get: { engine.settings.theme },
                                                  set: { engine.settings.theme = $0 })) {
                    ForEach(FaceTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                Toggle("24 часа", isOn: Binding(get: { engine.settings.use24h },
                                                set: { engine.settings.use24h = $0 }))
                Toggle("Секунды", isOn: Binding(get: { engine.settings.showSeconds },
                                                set: { engine.settings.showSeconds = $0 }))
                VStack(alignment: .leading) {
                    Text("Подсветка \(Int(engine.settings.backlightSeconds)) с")
                        .font(.system(size: 13, design: .monospaced))
                    Slider(value: Binding(get: { engine.settings.backlightSeconds },
                                          set: { engine.settings.backlightSeconds = $0 }),
                           in: 1...10, step: 1)
                }
            }

            Section("МОДУЛЬ") {
                Toggle("Часовой сигнал", isOn: Binding(get: { engine.settings.hourlyChime },
                                                       set: { value in
                    engine.settings.hourlyChime = value
                    engine.alarms.setHourlyChime(value)
                }))
                Toggle("Колёсико меняет режим", isOn: Binding(get: { engine.settings.crownSwitchesMode },
                                                              set: { engine.settings.crownSwitchesMode = $0 }))
                Picker("Второй пояс", selection: Binding(get: { engine.settings.dualTimeZoneID },
                                                         set: { engine.settings.dualTimeZoneID = $0 })) {
                    ForEach(DualTimeModeView.cities, id: \.self) { city in
                        Text(TimeFormat.cityCode(TimeZone(identifier: city) ?? .current)).tag(city)
                    }
                }
                Picker("Окно данных", selection: Binding(get: { engine.settings.pinnedReadout },
                                                         set: { engine.settings.pinnedReadout = $0 })) {
                    ForEach(FaceSettings.Readout.allCases) { readout in
                        Text(readout.code).tag(readout)
                    }
                }
            }

            Section("РЕЖИМЫ") {
                ForEach(engine.availableModes) { mode in
                    Button {
                        engine.select(mode)
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode.code)
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            Text(mode.title)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if engine.mode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}
