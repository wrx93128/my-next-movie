import SwiftUI

private let backdropHeight: CGFloat = 440
private let backdropBlurRadius: CGFloat = 40
private let posterWidthOnBackdrop: CGFloat = 200
private let posterShadowColor = Color.black.opacity(0.35)
private let posterShadowRadius: CGFloat = 20
private let posterShadowOffset: CGFloat = 10

struct MovieDetailView: View {
    let movie: Movie
    @State private var viewModel: MovieDetailViewModel

    init(movie: Movie, loadDetails: @escaping MovieDetailsLoader) {
        self.movie = movie
        _viewModel = State(initialValue: MovieDetailViewModel(movieId: movie.id, loadDetails: loadDetails))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacingExtraLarge) {
                MovieBackdrop(movie: movie)
                MovieInfo(movie: movie, details: viewModel.details).padding(.horizontal)
                detailsContent.padding(.horizontal)
            }
            .padding(.bottom, spacingHuge)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var detailsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical)
        case .loaded:
            MovieDetailSections(details: viewModel.details)
        case .failed:
            VStack(spacing: spacingMedium) {
                Text(viewModel.errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }
}

/// The poster, sharp, on top of itself stretched to the screen width and blurred.
private struct MovieBackdrop: View {
    let movie: Movie

    var body: some View {
        GeometryReader { geometry in
            BlurredPoster(movie: movie, backdropSize: geometry.size)
        }
        .frame(height: backdropHeight)
        .clipped()
        .overlay { fadeToBackground }
        .overlay(alignment: .bottom) { sharpPoster }
    }

    private var fadeToBackground: some View {
        LinearGradient(
            colors: [.clear, Color(.systemBackground)],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    private var sharpPoster: some View {
        PosterView(movie: movie)
            .frame(width: posterWidthOnBackdrop)
            .shadow(color: posterShadowColor, radius: posterShadowRadius, y: posterShadowOffset)
    }
}

private struct BlurredPoster: View {
    let movie: Movie
    let backdropSize: CGSize

    var body: some View {
        PosterView(movie: movie, cornerRadius: 0)
            .frame(width: backdropSize.width)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: backdropSize.width, height: backdropSize.height)
            .blur(radius: backdropBlurRadius, opaque: true)
    }
}

private struct MovieInfo: View {
    let movie: Movie
    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: spacingLarge) {
            heading
            GenreRow(genreIds: knownGenreIds(movie))
            overview
            directedBy
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            Text(movie.title)
                .font(.system(.largeTitle, design: .serif, weight: .bold))

            if !details.tagline.isEmpty {
                Text(details.tagline)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            let facts = movieFactsLine(movie, details)
            if !facts.isEmpty {
                Text(facts)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var overview: some View {
        if !movie.overview.isEmpty {
            VStack(alignment: .leading) {
                Text("Overview")
                    .font(.headline)

                Text(movie.overview)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var directedBy: some View {
        let directors = directorNames(details)
        if !directors.isEmpty {
            VStack(alignment: .leading, spacing: spacingExtraSmall) {
                Text("Directed by")
                    .font(.headline)

                Text(directors)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Genre chips in one row that scrolls sideways when they do not fit.
private struct GenreRow: View {
    let genreIds: [Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacingSmall) {
                ForEach(genreIds, id: \.self) { genreId in
                    GenreChip(genreId: genreId)
                }
            }
        }
        .scrollClipDisabled()
    }
}

#Preview {
    NavigationStack {
        PopularMoviesPreview { movies in
            MovieDetailView(movie: movies[0], loadDetails: fetchMovieDetails)
        }
    }
}
