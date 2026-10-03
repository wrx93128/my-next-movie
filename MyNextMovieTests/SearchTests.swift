import Testing

@testable import MyNextMovie

@MainActor
struct FilterMoviesTests {
    @Test func emptyQueryAndNoGenreReturnsEveryMovie() {
        #expect(filterMovies(sampleMovies, query: "", genreId: noGenreId) == sampleMovies)
    }

    @Test func matchesTitleIgnoringCase() {
        let foundMovies = filterMovies(sampleMovies, query: "matrix", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["The Matrix"])
    }

    @Test func matchesKeywordInOverview() {
        let foundMovies = filterMovies(sampleMovies, query: "wormhole", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Interstellar"])
    }

    // TODO: Lab 2, task 1. Check that diacritics do not matter: build a `Movie` titled "Amélie"
    // (other fields empty, `posterPath: nil`) and expect `filterMovies` to find it for "amelie".
    @Test()
    func ignoresDiacritics() {
        let movieAmelie = Movie(
            id: -1,
            title: "Amélie",
            overview: "",
            releaseDate: "",
            posterPath: nil,
            voteAverage: 0.0,
            genreIds: []
        )
        let foundMovies = filterMovies([movieAmelie], query: "amelie", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Amélie"])
    }

    @Test func filtersByGenre() {
        let foundMovies = filterMovies(sampleMovies, query: "", genreId: genreIdAnimation)
        #expect(titlesOf(foundMovies) == ["Spirited Away"])
    }

    // TODO: Lab 2, task 1. Check that the query and the genre must both match:
    // "matrix" with `genreIdAnimation` finds nothing in `sampleMovies`.
    @Test()
    func combinesQueryAndGenre() {
        let foundMovies = filterMovies(sampleMovies, query: "matrix", genreId: genreIdAnimation)
        #expect(foundMovies.isEmpty)
    }

    @Test func trimsSpacesAroundQuery() {
        let foundMovies = filterMovies(sampleMovies, query: "  inception ", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Inception"])
    }
}

@MainActor
struct SearchViewModelTests {
    @Test func staysIdleWithoutQueryOrGenre() async {
        let viewModel = SearchViewModel(searchMovies: { _, _ in sampleMovies })
        viewModel.query = "   "

        await viewModel.search()

        #expect(viewModel.state == .idle)
    }

    // TODO: Lab 2, task 1. Check what `search` passes to `searchMovies`.
    // Save the received query and genre id in variables inside the closure and return [].
    // Set `query` to " matrix " and `selectedGenreId` to `genreIdAction`, call `search()`,
    // then expect "matrix", `genreIdAction`, state `.loaded` and no movies.
    @Test()
    func passesTrimmedQueryAndGenreToSearch() async {
        let viewModel = SearchViewModel(searchMovies: { _, _ in [] })
        viewModel.query = "matrix"
        viewModel.selectedGenreId = genreIdAction

        await viewModel.search()

        #expect(viewModel.query == "matrix")
        #expect(viewModel.selectedGenreId == genreIdAction)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func showsErrorWhenSearchFails() async {
        let viewModel = SearchViewModel(searchMovies: { _, _ in throw NoConnection() })
        viewModel.query = "matrix"

        await viewModel.search()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    // TODO: Lab 2, task 1. Check that `toggleGenre` called twice with `genreIdAction`
    // first selects the genre, then clears it back to `noGenreId`.
    @Test()
    func togglingSelectedGenreClearsIt() {
        let viewModel = SearchViewModel(searchMovies: { _, _ in sampleMovies })
        viewModel.toggleGenre(genreIdAction)
        #expect(viewModel.selectedGenreId == genreIdAction)

        viewModel.toggleGenre(genreIdAction)
        #expect(viewModel.selectedGenreId == noGenreId)
    }
}

private func titlesOf(_ movies: [Movie]) -> [String] {
    var movieTitles: [String] = []
    for movie in movies {
        movieTitles.append(movie.title)
    }
    return movieTitles
}
