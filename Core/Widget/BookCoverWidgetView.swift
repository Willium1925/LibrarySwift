//
//  BookCoverWidgetView.swift
//  LibrarySwift
//
//  Created by fcuiecs on 2025/10/27.
import WidgetKit
import SwiftUI
import Foundation

// MARK: - Entry 資料結構
struct BookCarouselEntry: TimelineEntry {
    let date: Date
    let books: [Book]
}

// MARK: - Provider
struct BookCarouselProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookCarouselEntry {
        // 預覽時顯示的假資料（不會在正式環境中用到）
        BookCarouselEntry(
            date: Date(),
            books: [
                Book(id: 1, title: "Loading...", author: "", category: "", publishYear: 2024, publisher: "", availableCopies: 0, totalCopies: 0, imageUrl: nil)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BookCarouselEntry) -> ()) {
        Task {
            do {
                let books = try await APIService.shared.fetchBooks()
                let entry = BookCarouselEntry(date: Date(), books: books)
                completion(entry)
            } catch {
                print("❌ Snapshot API fetch failed: \(error)")
                completion(placeholder(in: context))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookCarouselEntry>) -> ()) {
        Task {
            do {
                let books = try await APIService.shared.fetchBooks()
                let entry = BookCarouselEntry(date: Date(), books: books)
                
                // 設定下一次更新時間（例如 30 分鐘後）
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                print("❌ Timeline API fetch failed: \(error)")
                completion(Timeline(entries: [placeholder(in: context)], policy: .after(Date().addingTimeInterval(60 * 10))))
            }
        }
    }
}

// MARK: - Widget View
struct BookCarouselWidgetEntryView: View {
    var entry: BookCarouselProvider.Entry
    
    @State private var currentIndex = 0
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geometry in
            if entry.books.isEmpty {
                Text("沒有書籍資料")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(entry.books.prefix(5).enumerated()), id: \.element.id) { index, book in
                        VStack {
                            // 書籍圖片
                            if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: geometry.size.height * 0.6)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: geometry.size.height * 0.6)
                                            .cornerRadius(8)
                                    case .failure:
                                        Image(systemName: "book.closed")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: geometry.size.height * 0.6)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "book.closed")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: geometry.size.height * 0.6)
                                    .foregroundColor(.gray)
                            }

                            // 書名 + 作者
                            Text(book.title)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                                .lineLimit(2)

                            Text(book.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            }
        }
    }
}

// MARK: - Widget 定義
//@main
struct BookCarouselWidget: Widget {
    let kind: String = "BookCarouselWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookCarouselProvider()) { entry in
            BookCarouselWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("📚 書籍輪播")
        .description("自動從後端載入最新的書籍資料，顯示可輪播的封面。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

