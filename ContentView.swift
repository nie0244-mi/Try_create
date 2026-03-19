import SwiftUI

struct ContentView: View {
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var text3 = ""
    @State private var saved: (String, String, String)? = nil
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Text("メモ記録")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 16) {
                TextField("テキスト 1", text: $text1)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                TextField("テキスト 2", text: $text2)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                TextField("テキスト 3", text: $text3)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
            }
            .padding(.horizontal)

            Button(action: {
                saved = (text1, text2, text3)
                showAlert = true
            }) {
                Text("記録する")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .alert("保存しました", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }

            Divider()

            if let s = saved {
                VStack(alignment: .leading, spacing: 12) {
                    Text("保存済みの記録")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Group {
                        LabeledRow(label: "テキスト 1", value: s.0)
                        LabeledRow(label: "テキスト 2", value: s.1)
                        LabeledRow(label: "テキスト 3", value: s.2)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text("まだ記録がありません")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "（空）" : value)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
        }
        .font(.body)
    }
}
