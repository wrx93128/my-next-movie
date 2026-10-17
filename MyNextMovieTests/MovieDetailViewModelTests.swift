import Testing

@testable import MyNextMovie

@MainActor
struct MovieDetailViewModelTests {
    @Test func startsIdleWithEmptyDetails() {
        let viewModel = MovieDetailViewModel(movieId: 603, loadDetails: { _ in emptyMovieDetails })

        #expect(viewModel.state == .idle)
        #expect(viewModel.details.credits.cast.isEmpty)
    }

    @Test func loadsDetailsOfItsMovie() async {
        let expectedMovieId = testMovieDetails.id
        var loadedMovieId: Int?

        let viewModel = MovieDetailViewModel(movieId: expectedMovieId) { id in
            loadedMovieId = id
            return testMovieDetails
        }

        await viewModel.load()

        #expect(loadedMovieId == expectedMovieId)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.details.id == expectedMovieId)
    }

    @Test func showsErrorWhenLoadingFails() async {
        let viewModel = MovieDetailViewModel(movieId: 603) { _ in
            throw NoConnection()
        }

        await viewModel.load()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test func loadIfNeededLoadsOnlyOnce() async {
        var callCount = 0
        let viewModel = MovieDetailViewModel(movieId: 603) { _ in
            callCount += 1
            return emptyMovieDetails
        }

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(callCount == 1)
    }
}
