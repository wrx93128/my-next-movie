import SwiftUI

struct PopularMoviesPreview<Content: View>: View {
    @ViewBuilder let content: ([Movie]) -> Content

    @State private var movies: [Movie] = []
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let errorMessage {
                Text(errorMessage)
            } else if isLoading {
                ProgressView()
            } else {
                content(movies)
            }
        }
        .task {
            do {
                movies = try await fetchPopularMovies()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
