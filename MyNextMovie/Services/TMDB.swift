import Foundation

private let tmdbScheme = "https"
private let tmdbHost = "api.themoviedb.org"
private let tmdbPopularPath = "/3/movie/popular"
private let tmdbSearchPath = "/3/search/movie"
private let tmdbDiscoverPath = "/3/discover/movie"
private let tmdbMoviePathPrefix = "/3/movie/"

private let tmdbAPIKeyParam = "api_key"
private let tmdbQueryParam = "query"
private let tmdbWithGenresParam = "with_genres"
private let tmdbAppendToResponseParam = "append_to_response"

let httpStatusOK = 200
let httpStatusUnauthorized = 401

nonisolated struct TMDBMoviePage: Decodable {
    let results: [Movie]
}

struct TMDBError: LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
}

func tmdbURL(path: String, parameters: [URLQueryItem], apiKey: String) -> URL? {
    var components = URLComponents()
    components.scheme = tmdbScheme
    components.host = tmdbHost
    components.path = path

    var queryItems = [URLQueryItem(name: tmdbAPIKeyParam, value: apiKey)]
    queryItems.append(contentsOf: parameters)

    components.queryItems = queryItems
    return components.url
}

func tmdbPopularURL(apiKey: String) -> URL? {
    return tmdbURL(path: tmdbPopularPath, parameters: [], apiKey: apiKey)
}

func tmdbSearchURL(query: String, genreId: Int, apiKey: String) -> URL? {
    let trimmedQuery = query.trimmingCharacters(in: .whitespaces)

    if trimmedQuery.isEmpty {
        var parameters: [URLQueryItem] = []
        if genreId != noGenreId {
            parameters.append(URLQueryItem(name: tmdbWithGenresParam, value: String(genreId)))
        }
        return tmdbURL(path: tmdbDiscoverPath, parameters: parameters, apiKey: apiKey)
    } else {
        return tmdbURL(
            path: tmdbSearchPath,
            parameters: [URLQueryItem(name: tmdbQueryParam, value: trimmedQuery)],
            apiKey: apiKey
        )
    }
}

func tmdbMovieDetailsURL(movieId: Int, apiKey: String) -> URL? {
    return tmdbURL(
        path: "\(tmdbMoviePathPrefix)\(movieId)",
        parameters: [
            URLQueryItem(
                name: tmdbAppendToResponseParam,
                value: "credits,videos,release_dates,watch/providers,recommendations"
            )
        ],
        apiKey: apiKey
    )
}

func decodeTMDBMovies(_ data: Data) throws -> [Movie] {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let page = try decoder.decode(TMDBMoviePage.self, from: data)
    return page.results
}

func checkTMDBResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else { return }

    if httpResponse.statusCode == httpStatusUnauthorized {
        throw TMDBError(message: "Invalid TMDB API key (401).")
    } else if httpResponse.statusCode != httpStatusOK {
        throw TMDBError(message: "HTTP error \(httpResponse.statusCode)")
    }
}

private func fetchTMDBData(_ address: URL?) async throws -> Data {
    guard let url = address else {
        throw TMDBError(message: "Nieprawidłowy adres URL.")
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    try checkTMDBResponse(response)

    return data
}

func fetchPopularMovies() async throws -> [Movie] {
    let apiKey = tmdbAPIKey()
    guard !apiKey.isEmpty else {
        throw TMDBError(message: "Missing TMDB API key. Add it to Config/Secrets.xcconfig.")
    }

    let url = tmdbPopularURL(apiKey: apiKey)
    let data = try await fetchTMDBData(url)
    return try decodeTMDBMovies(data)
}

func searchTMDBMovies(query: String, genreId: Int) async throws -> [Movie] {
    let apiKey = tmdbAPIKey()
    guard !apiKey.isEmpty else {
        throw TMDBError(message: "Missing TMDB API key. Add it to Config/Secrets.xcconfig.")
    }

    let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
    let url = tmdbSearchURL(query: trimmedQuery, genreId: genreId, apiKey: apiKey)

    let data = try await fetchTMDBData(url)
    let movies = try decodeTMDBMovies(data)

    if !trimmedQuery.isEmpty {
        return filterMovies(movies, query: "", genreId: genreId)
    } else {
        return movies
    }
}

func decodeTMDBMovieDetails(_ data: Data) throws -> MovieDetails {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(MovieDetails.self, from: data)
}

func fetchMovieDetails(movieId: Int) async throws -> MovieDetails {
    let apiKey = tmdbAPIKey()
    guard !apiKey.isEmpty else {
        throw TMDBError(message: "Missing TMDB API key. Add it to Config/Secrets.xcconfig.")
    }

    let url = tmdbMovieDetailsURL(movieId: movieId, apiKey: apiKey)
    let data = try await fetchTMDBData(url)
    return try decodeTMDBMovieDetails(data)
}
