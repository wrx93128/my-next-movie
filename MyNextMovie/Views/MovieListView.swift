import SwiftUI

private let gridMinimumColumnWidth: CGFloat = 150

struct MovieListView: View {
    @State private var viewModel: MovieListViewModel

    init(viewModel: MovieListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Next Movie")
                .navigationDestination(for: Movie.self) { movie in MovieDetailView(movie: movie) }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingGrid
        case .loaded:
            loadedGrid
        case .failed:
            ErrorView(title: "Could not load movies", message: viewModel.errorMessage) {
                Task { await viewModel.load() }
            }
        }
    }

    /// Sample movies drawn as gray shapes while the real ones load.
    private var loadingGrid: some View {
        MovieGrid(title: "Popular", movies: sampleMovies)
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var loadedGrid: some View {
        if viewModel.movies.isEmpty {
            ContentUnavailableView("No movies", systemImage: symbolNameMovies)
        } else {
            MovieGrid(title: "Popular", movies: viewModel.movies)
        }
    }
}

private struct MovieGrid: View {
    let title: String
    let movies: [Movie]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacingLarge) {
                Text(title).font(.title2.bold())
                grid
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // TODO: Lab 1, task 1. Replace the text with a `LazyVGrid`:
    // - columns: one `GridItem(.adaptive(minimum: gridMinimumColumnWidth), spacing: spacingLarge)`,
    //   so the grid fits as many columns as the screen width allows,
    // - row spacing: `spacingExtraLarge`,
    // - content: `ForEach(movies)` with a `MovieGridItem` for every movie.
    private var grid: some View {
        let columns = [
            GridItem(.adaptive(minimum: gridMinimumColumnWidth), spacing: spacingLarge)
        ]

        return LazyVGrid(columns: columns, spacing: spacingExtraLarge) {
            ForEach(movies) { movie in
                MovieGridItem(movie: movie)
            }
        }
    }
}

/// One cell of the grid. Tapping it opens the movie details.
private struct MovieGridItem: View {
    let movie: Movie
    // TODO: Lab 1, task 1. Wrap the card in `NavigationLink(value: movie)`.
    // `MovieListView` already turns the value into a `MovieDetailView`
    // with `.navigationDestination(for: Movie.self)`.
    // Add `.buttonStyle(.plain)`, otherwise the whole card turns blue.
    var body: some View {
        NavigationLink(value: movie) {
            MovieCardView(movie: movie)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MovieListView(viewModel: MovieListViewModel(loadMovies: loadSampleMovies))
}
