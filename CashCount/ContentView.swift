import SwiftUI

struct ContentView: View {
    @StateObject private var store = CountStore()
    @State private var account = 0
    @State private var showReset = false
    @FocusState private var focused: Entry?
    @ScaledMetric(relativeTo: .body) private var tabletPanelHeight: CGFloat = 800
    private let names = ["レジ", "金庫"]

    private struct Entry: Hashable {
        let denomination: Int
        let roll: Bool
    }

    private var entries: [Entry] {
        MoneyCount.denominations.flatMap { value in
            value <= 500 ? [Entry(denomination: value, roll: false), Entry(denomination: value, roll: true)]
                : [Entry(denomination: value, roll: false)]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let spacious = geometry.size.width >= 700
            countPanel(spacious: spacious)
                .frame(maxWidth: 720)
                .frame(height: spacious ? min(geometry.size.height, tabletPanelHeight) : geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func countPanel(spacious: Bool) -> some View {
        VStack(spacing: spacious ? 16 : 8) {
            Picker("保管場所", selection: $account) {
                ForEach(0..<2) { Text(names[$0]).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: account) { _, _ in focused = nil }

            ScrollViewReader { proxy in
                ScrollView {
                    Grid(horizontalSpacing: spacious ? 12 : 6, verticalSpacing: spacious ? 8 : 4) {
                        GridRow {
                            Text("金種")
                            Text("枚数")
                            Text("ロール")
                            Text("小計（円）")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        ForEach(MoneyCount.denominations, id: \.self) { value in
                            GridRow {
                                Text("\(value.formatted())円")
                                    .font(spacious ? .body.weight(.medium) : .subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                input(value, roll: false, spacious: spacious)
                                if value <= 500 { input(value, roll: true, spacious: spacious) }
                                else { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                                Text(store.accounts[account].subtotal(value).formatted())
                                    .font(spacious ? .body.bold() : .subheadline.bold())
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel("\(value)円の小計 \(store.accounts[account].subtotal(value))円")
                            }
                            .id(value)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focused) { _, entry in
                    if let entry { withAnimation { proxy.scrollTo(entry.denomination, anchor: .center) } }
                }
            }
        }
        .padding(.top, spacious ? 24 : 8)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Button("リセット", role: .destructive) { focused = nil; showReset = true }
                    .font(.subheadline)
                    .frame(minHeight: 44)
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("合計").font(.caption).foregroundStyle(.secondary)
                    Text("¥\(store.accounts[account].total.formatted())")
                        .font(.title2.bold()).monospacedDigit()
                        .minimumScaleFactor(0.5).lineLimit(1)
                        .accessibilityLabel("合計 \(store.accounts[account].total)円")
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(.bar)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("次へ") { nextEntry() }
                Spacer()
                Button("完了") { focused = nil }
            }
        }
        .confirmationDialog("\(names[account])の入力をリセットしますか？", isPresented: $showReset, titleVisibility: .visible) {
            Button("リセット", role: .destructive) { store.reset(account: account) }
            Button("キャンセル", role: .cancel) { }
        }
    }

    private func input(_ value: Int, roll: Bool, spacious: Bool) -> some View {
        CountField(count: store.accounts[account].count(value, roll: roll)) { text in
            store.set(text, account: account, denomination: value, roll: roll)
        }
        .id(account)
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: spacious ? 52 : 44)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .focused($focused, equals: Entry(denomination: value, roll: roll))
        .accessibilityLabel("\(value)円 \(roll ? "ロール数、1ロール50枚" : "枚数")")
    }

    private func nextEntry() {
        guard let focused, let index = entries.firstIndex(of: focused), index + 1 < entries.count else {
            focused = nil
            return
        }
        self.focused = entries[index + 1]
    }
}

private struct CountField: View {
    let count: Int
    let onEdit: (String) -> Void
    @State private var text = ""

    private func display(_ value: Int) -> String {
        value == 0 ? "" : String(value)
    }

    var body: some View {
        TextField("0", text: $text)
            .onChange(of: text) { _, edited in
                let value = MoneyCount.normalized(edited)
                text = display(value)
                if value != count { onEdit(text) }
            }
            .onChange(of: count, initial: true) { _, value in
                text = display(value)
            }
    }
}
