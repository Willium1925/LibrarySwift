//
//  BookCoverCarouselView.swift
//  LibrarySwift
//
//  Created by fcuiecs on 2025/10/27.
//
import SwiftUI

struct BookCoverCarouselView: View {
    @State private var books: [Book] = []
    @State private var selectedCategory: String = "所有書籍"
    @State private var currentIndex: Int = 0

    let categories = ["所有書籍", "文學小說", "漫畫", "程式設計", "心理勵志"]
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var filteredBooks: [Book] {
        selectedCategory == "所有書籍" ? books : books.filter { $0.category == selectedCategory }
    }

    // 🔹 用第一本書作為「熱門」示意
    var popularBookId: Int? {
        filteredBooks.first?.id
    }

    var body: some View {
        VStack(spacing: 16) {

            // 分類選擇
            Picker("分類", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // 書籍封面輪播
            if !filteredBooks.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(filteredBooks.enumerated()), id: \.offset) { index, book in
                        ZStack(alignment: .topTrailing) {

                            VStack(spacing: 6) {
                                AsyncImage(url: URL(string: book.imageUrl ?? "")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else if phase.error != nil {
                                        Color.red.opacity(0.3) // 圖片載入失敗
                                    } else {
                                        Color.gray.opacity(0.3) // 載入中
                                    }
                                }
                                .frame(width: 120, height: 160)
                                .cornerRadius(8)
                                .clipped()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text("作者：\(book.author)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("出版社：\(book.publisher)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("出版年份：\(book.publishYear)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                            }

                            // 🔥 熱門書標籤（示意）
                            if book.id == popularBookId {
                                Text("🔥 熱門")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.orange.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .offset(x: -6, y: 6)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 250)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % filteredBooks.count
                    }
                }
            }

            Spacer()
        }
        .task {
            await fetchBooksFromAPI()
        }
    }

    // 撈取書籍資料
    func fetchBooksFromAPI() async {
        do {
            books = try await APIService.shared.fetchBooks()
        } catch {
            print("抓書籍資料失敗：\(error)")
        }
    }
}

#Preview {
    BookCoverCarouselView()
}
