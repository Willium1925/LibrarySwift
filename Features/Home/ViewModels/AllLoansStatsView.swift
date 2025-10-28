import SwiftUI
import Charts

struct AllLoansStatsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var vm = StatsAllViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("曾經借過的所有書籍統計")
                .font(.title3).bold()
                .padding(.horizontal)

            content
        }
        .task {
            if let userId = authManager.loggedInUser?.id {
                await vm.load(userId: userId)
            }
        }
        .navigationTitle("統計")
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let msg = vm.errorMessage {
            Text(msg)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
        } else if vm.loans.isEmpty {
            Text("目前沒有統計資料")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
        } else {
            // 以書名對應分類：Book.title -> category（對不到 → 未分類）
            let bookByTitle = Dictionary(uniqueKeysWithValues: vm.books.map { ($0.title, $0) })
            let names: [String] = vm.loans.map { loan in
                bookByTitle[loan.title]?.category ?? "未分類"
            }

            let counts = Dictionary(grouping: names, by: { $0 }).mapValues { $0.count }
            let total = counts.values.reduce(0, +)
            let top3: [(name: String, percent: Double, count: Int)] =
                counts.sorted { $0.value > $1.value }
                      .prefix(3)
                      .map { (key, value) in
                          (name: key,
                           percent: total > 0 ? Double(value) / Double(total) : 0.0,
                           count: value)
                      }

            // 水平長條圖（iOS 16+）
            Chart(top3, id: \.name) { item in
                BarMark(
                    x: .value("百分比", item.percent),
                    y: .value("分類", item.name)
                )
                .annotation(position: .trailing) {
                    Text(item.percent.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption).bold()
                }
            }
            .frame(height: CGFloat(48 * max(1, top3.count)))
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v.formatted(.percent))
                        }
                    }
                }
            }
            .padding(.horizontal)

            // 圓餅圖（iOS 17+）
            if #available(iOS 17.0, *) {
                Divider().padding(.horizontal)
                Chart(top3, id: \.name) { item in
                    SectorMark(
                        angle: .value("百分比", item.percent),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("分類", item.name))
                    .annotation(position: .overlay) {
                        if item.percent >= 0.07 {
                            VStack(spacing: 2) {
                                Text(item.name).font(.caption2).bold()
                                Text(item.percent.formatted(.percent.precision(.fractionLength(0))))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)
            }

            Text("樣本數：\(total)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    AllLoansStatsView()
        .environment(AuthenticationManager())
}
