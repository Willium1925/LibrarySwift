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

                            VStack {
                                AsyncImage(url: URL(string: book.imageUrl ?? "")) { image in
                                    image.resizable()
                                         .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 120, height: 160)
                                .cornerRadius(8)
                                .clipped()

                                Text(book.title)
                                    .font(.caption)
                                    .lineLimit(1)
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
                .frame(height: 200)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % filteredBooks.count
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
                    .padding(.top, 8)
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

