//
//  BookCoverWidgetView.swift
//  LibrarySwift
//
//  Created by fcuiecs on 2025/10/27.
import WidgetKit
import SwiftUI

// 🔹 Widget Timeline Entry
struct BookCoverEntry: TimelineEntry {
    let date: Date
    let books: [Book]
}

// 🔹 Timeline Provider
struct BookCoverProvider: TimelineProvider {
    typealias Entry = BookCoverEntry

    func placeholder(in context: Context) -> BookCoverEntry {
        BookCoverEntry(date: Date(), books: [
            Book(id: 1, title: "示範書籍", author: "作者", category: "文學小說",
                 publishYear: 2020, publisher: "出版社", availableCopies: 3, totalCopies: 3, imageUrl: nil)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (BookCoverEntry) -> Void) {
        Task {
            let books = try? await APIService.shared.fetchBooks()
            completion(BookCoverEntry(date: Date(), books: books ?? []))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookCoverEntry>) -> Void) {
        Task {
            let books = try? await APIService.shared.fetchBooks()
            let entry = BookCoverEntry(date: Date(), books: books ?? [])
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// 🔹 Widget 主視圖
struct BookCoverWidgetView: View {
    let entry: BookCoverEntry
    @State private var selectedCategory: String = "所有書籍"
    @State private var currentIndex: Int = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    let categories: [String] = ["所有書籍", "文學小說", "漫畫", "程式設計", "心理勵志"]

    var filteredBooks: [Book] {
        selectedCategory == "所有書籍" ? entry.books : entry.books.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 6) {

            // 分類 Picker
            Picker("分類", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .top])

            GeometryReader { geo in
                if filteredBooks.isEmpty {
                    Text("暫無書籍資料")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 封面輪播
                    TabView(selection: $currentIndex) {
                        ForEach(Array(filteredBooks.enumerated()), id: \.offset) { index, book in
                            VStack {
                                AsyncImage(url: URL(string: book.imageUrl ?? "")) { image in
                                    image.resizable()
                                         .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: geo.size.width, height: geo.size.height * 0.7)
                                .clipped()
                                .cornerRadius(8)

                                Text(book.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .onReceive(timer) { _ in
                        withAnimation {
                            currentIndex = (currentIndex + 1) % filteredBooks.count
                        }
                    }
                }
            }

            // 簡單統計
            if !filteredBooks.isEmpty {
                let total = filteredBooks.count
                let available = filteredBooks.filter { $0.availableCopies > 0 }.count
                Text("📘 \(selectedCategory) 共 \(total) 本，剩餘 \(available) 本可借")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }

            Spacer()
        }
    }
}

// 🔹 Widget 定義
struct BookCoverCarouselWidget: Widget {
    let kind: String = "BookCoverCarouselWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookCoverProvider()) { entry in
            BookCoverWidgetView(entry: entry)
        }
        .configurationDisplayName("書籍封面輪播")
        .description("顯示圖書館書籍封面，輪播展示最新書籍。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// 🔹 Preview
struct BookCoverCarouselWidget_Previews: PreviewProvider {
    static var previews: some View {
        BookCoverWidgetView(entry: BookCoverEntry(date: Date(), books: [
            Book(id: 1, title: "GOTH斷掌事件", author: "乙一", category: "文學小說", publishYear: 2002, publisher: "皇冠文化", availableCopies: 3, totalCopies: 3, imageUrl: nil),
            Book(id: 2, title: "Java SE 17 技術手冊", author: "林信良", category: "程式設計", publishYear: 2019, publisher: "碁峯資訊", availableCopies: 2, totalCopies: 3, imageUrl: nil)
        ]))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

