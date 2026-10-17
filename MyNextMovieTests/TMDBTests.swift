import Foundation
import Testing

@testable import MyNextMovie

private let matrixMoviePageJSON = """
    {
        "page": 1,
        "results": [
        {
            "id": 603,
            "title": "The Matrix",
            "overview": "A hacker learns that the world is a simulation.",
            "release_date": "1999-03-31",
            "poster_path": "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
            "vote_average": 8.2,
            "genre_ids": [28, 878]
        }
        ]
    }
    """

private let nullPosterMoviePageJSON = """
    {
        "page": 1,
        "results": [
        {
            "id": 603,
            "title": "The Matrix",
            "overview": "A hacker learns that the world is a simulation.",
            "release_date": "1999-03-31",
            "poster_path": null,
            "vote_average": 8.2,
            "genre_ids": [28, 878]
        }
        ]
    }
    """

private let otherJSON = """
    {
        "status_code": 7
    }
    """

@MainActor
struct TMDBTests {
    @Test func decodesSnakeCaseKeys() throws {
        let data = try #require(matrixMoviePageJSON.data(using: .utf8))
        let movies = try decodeTMDBMovies(data)
        let movie = try #require(movies.first)

        #expect(movie.releaseDate == "1999-03-31")
        #expect(movie.posterPath == "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg")
        #expect(movie.voteAverage == 8.2)
        #expect(movie.genreIds == [28, 878])
    }

    @Test func decodesMissingPosterAsNil() throws {
        let data = try #require(nullPosterMoviePageJSON.data(using: .utf8))
        let movies = try decodeTMDBMovies(data)
        let movie = try #require(movies.first)

        #expect(movie.posterPath == nil)
    }

    @Test func decodingFailsForOtherJSON() throws {
        let data = try #require(otherJSON.data(using: .utf8))
        #expect(throws: DecodingError.self) {
            try decodeTMDBMovies(data)
        }
    }

    @Test func popularURLHasAPIKey() throws {
        let popularURL = try #require(tmdbPopularURL(apiKey: "test-key"))
        #expect(popularURL.absoluteString == "https://api.themoviedb.org/3/movie/popular?api_key=test-key")
    }

    @Test func searchWithTextUsesSearchEndpoint() throws {
        let searchURL = try #require(tmdbSearchURL(query: "matrix", genreId: noGenreId, apiKey: "test-key"))
        #expect(searchURL.path() == "/3/search/movie")
        let components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "query", value: "matrix")) == true)
    }

    @Test func searchWithGenreOnlyUsesDiscoverEndpoint() throws {
        let searchURL = try #require(tmdbSearchURL(query: "", genreId: genreIdAnimation, apiKey: "test-key"))
        #expect(searchURL.path() == "/3/discover/movie")
        let components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "with_genres", value: String(genreIdAnimation))) == true)
    }

    @Test func searchTextIsPercentEncoded() throws {
        let searchURL = try #require(tmdbSearchURL(query: "pan tadeusz", genreId: noGenreId, apiKey: "test-key"))
        #expect(searchURL.absoluteString.contains("query=pan%20tadeusz"))
    }

    @Test func detailsURLAppendsEveryPart() throws {
        let detailsURL = try #require(tmdbMovieDetailsURL(movieId: 603, apiKey: "test-key"))
        #expect(detailsURL.path() == "/3/movie/603")
        let components = URLComponents(url: detailsURL, resolvingAgainstBaseURL: false)
        let appendItem = components?.queryItems?.first(where: { $0.name == "append_to_response" })
        let appendValue = try #require(appendItem?.value)

        let parts = ["credits", "videos", "release_dates", "watch/providers", "recommendations"]
        for part in parts {
            #expect(appendValue.contains(part))
        }
    }

    @Test func okResponsePasses() throws {
        let url = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        #expect(throws: Never.self) {
            try checkTMDBResponse(response)
        }
    }

    @Test func unauthorizedResponseMentionsAPIKey() throws {
        let url = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil))
        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }
        #expect(thrownError?.message.contains("API key") == true)
    }

    @Test func otherErrorResponseShowsStatus() throws {
        let url = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }
        #expect(thrownError?.message.contains("404") == true)
    }
}
