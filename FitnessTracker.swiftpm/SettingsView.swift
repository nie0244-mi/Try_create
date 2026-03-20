import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds: Int = 90
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @AppStorage("autoStartRestTimer") private var autoStartRestTimer: Bool = true

    @EnvironmentObject var dataStore: DataStore
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            Form {

                // MARK: タイマー設定
                Section {
                    HStack {
                        Label("デフォルト休憩時間", systemImage: "timer")
                        Spacer()
                        Stepper(
                            "\(defaultRestSeconds)秒",
                            value: $defaultRestSeconds,
                            in: 15...300,
                            step: 15
                        )
                        .fixedSize()
                    }

                    Toggle(isOn: $autoStartRestTimer) {
                        Label("セット後に自動で休憩タイマー", systemImage: "bolt.fill")
                    }
                } header: {
                    Text("タイマー")
                } footer: {
                    Text("セットを記録した直後に休憩タイマーを自動起動します。")
                }

                // MARK: 重量単位
                Section {
                    Picker(selection: $weightUnit) {
                        Text("キログラム (kg)").tag("kg")
                        Text("ポンド (lbs)").tag("lbs")
                    } label: {
                        Label("重量単位", systemImage: "scalemass.fill")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("単位")
                }

                // MARK: 広告スペース（アフィリエイト用）
                Section {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(.orange)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("アフィリエイト広告")
                                .font(.body)
                            Text("近日公開予定")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // TODO: AdMob / affiliate banner を設置
                        // AdBannerView()
                        Text("準備中")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("広告・連携")
                } footer: {
                    Text("将来的にアフィリエイト広告やスポンサーリンクを表示予定です。")
                }

                // MARK: データ管理
                Section {
                    HStack {
                        Text("記録したセッション数")
                        Spacer()
                        Text("\(dataStore.sessions.count) 件")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("記録した総セット数")
                        Spacer()
                        Text("\(dataStore.sessions.reduce(0) { $0 + $1.sets.count }) セット")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("すべての記録を削除", systemImage: "trash")
                    }
                } header: {
                    Text("データ管理")
                }

                // MARK: アプリ情報
                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("ビルド")
                        Spacer()
                        Text("1").foregroundColor(.secondary)
                    }
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }
                } header: {
                    Text("アプリについて")
                }
            }
            .navigationTitle("設定")
            .alert("記録を削除", isPresented: $showingResetAlert) {
                Button("削除する", role: .destructive) {
                    dataStore.sessions.forEach { dataStore.deleteSession(id: $0.id) }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべてのトレーニング記録が削除されます。この操作は元に戻せません。")
            }
        }
    }
}
