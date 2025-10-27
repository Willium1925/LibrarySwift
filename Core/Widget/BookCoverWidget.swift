//
//  BookCoverCarouselWidget.swift
//  LibrarySwift
//
//  Created by fcuiecs on 2025/10/27.
//
//
//  BookCoverCarouselWidget.swift
//  LibrarySwiftWidget
//
//  Created by fcuiecs on 2025/10/27.
//

import WidgetKit
import SwiftUI

// 🔹 用於 Widget Timeline 的 Entry
struct BookCoverEntry: TimelineEntry {
    let date: Date
    let books: [Book]
}

// 🔹 TimelineProvider
struct BookCoverProvider: TimelineProvider {
    typealias Entry = BookCoverEntry
    
    // 預覽時用的靜態資料
    func placeholder(in context: Context) -> BookCoverEntry {
        BookCoverEntry(date: Date(), books: [
            Book(id: 1, title: "示範書籍", author: "作者", category: "文學小說",
                 publishYear: 2020, publisher: "出版社", availableCopies: 3, totalCopies: 3, imageUrl: nil)
        ])
    }
    
    // 快照 (Preview)
    func getSnapshot(in context: Context, completion: @escaping (BookCoverEntry) -> Void) {
        Task {
            let books = try? await fetchBooks()
            let entry = BookCoverEntry(date: Date(), books: books ?? [])
            completion(entry)
        }
    }
    
    // Timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<BookCoverEntry>) -> Void) {
        Task {
            let books = try? await fetchBooks()
            let entry = BookCoverEntry(date: Date(), books: books ?? [])
            // 更新時間：30 分鐘後
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    // 🔹 從 API 抓取書籍資料
    private func fetchBooks() async throws -> [Book] {
        // 呼叫你原本的 APIService
        try await APIService.shared.fetchBooks()
    }
}

// 🔹 Widget 的主要視圖
struct BookCoverWidgetView: View {
    let entry: BookCoverEntry
        
        // 🔹 可切換的分類
        let categories: [String] = ["所有書籍", "文學小說", "漫畫", "程式設計", "心理勵志"]
        
        // 🔹 Widget 狀態
        @State private var currentIndex = 0
        @State private var selectedCategory = "所有書籍"
        
        // 🔹 根據分類篩選書籍
        var filteredBooks: [Book] {
            selectedCategory == "所有書籍" ? entry.books : entry.books.filter { $0.category == selectedCategory }
        }
        
        var body: some View {
            VStack(spacing: 6) {
                
                // 🔹 分類切換 Picker
                Picker("分類", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.horizontal, .top])
                
                GeometryReader { geo in
                    if filteredBooks.isEmpty {
                        Text("暫無書籍資料")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 🔹 封面輪播
                        TabView(selection: $currentIndex) {
                            ForEach(Array(filteredBooks.enumerated()), id: \.offset) { index, book in
                                VStack {
                                    AsyncImage(url: URL(string: book.imageUrl ?? "")) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: geo.size.width, height: geo.size.height * 0.7)
                                    .clipped()
                                    
                                    Text(book.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                    }
                }
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
            Book(id: 1, title: "GOTH斷掌事件", author: "作者", category: "文學小說", publishYear: 2021, publisher: "出版社", availableCopies: 2, totalCopies: 3, imageUrl: nil),
            Book(id: 2, title: "Java SE 17 技術手冊", author: "作者", category: "程式設計", publishYear: 2022, publisher: "出版社", availableCopies: 1, totalCopies: 2, imageUrl: nil)
        ]))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

