import Testing

@testable import MyNextMovie

@MainActor
struct MovieListViewModelTests {
    @Test func startsIdle() {
        let viewModel = MovieListViewModel(loadMovies: { [] })

        #expect(viewModel.state == .idle)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func loadsMovies() async {
        let viewModel = MovieListViewModel(loadMovies: { sampleMovies })

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies == sampleMovies)
    }

    @Test func showsErrorWhenLoadingFails() async {
        let viewModel = MovieListViewModel(loadMovies: { throw NoConnection() })

        await viewModel.load()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    // TODO: Lab 1. Check that `loadIfNeeded` calls the loader only once.
    // Count the calls in a variable that the closure passed as `loadMovies` increments,
    // call `loadIfNeeded()` twice and expect a count of 1. The test has to be `async`.
    @Test()
    func loadIfNeededLoadsOnlyOnce() async {
        var callCount = 0
        let model = MovieListViewModel {
            callCount += 1
            return []
        }
        await model.loadIfNeeded()
        await model.loadIfNeeded()
        #expect(callCount == 1)
    }
}
