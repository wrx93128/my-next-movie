import Foundation

/// TMDB image server address for posters 500 pixels wide.
let tmdbPosterBaseURL = "https://image.tmdb.org/t/p/w500"

/// Number of characters of the year at the start of "1999-03-31".
let releaseYearLength = 4

/// One digit after the decimal point: 8.24 -> "8.2".
let ratingFormat = "%.1f"

let ratingStar = "★"

/// Goes between parts of a line of text: "1999 · Action".
let textSeparator = " · "

/// A movie as TMDB returns it.
/// TMDB JSON keys are snake_case, e.g. `release_date`.
/// Decode them with `JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`.
nonisolated struct Movie: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String  // "1999-03-31", empty when unknown
    let posterPath: String?  // nil when TMDB has no poster
    let voteAverage: Double
    let genreIds: [Int]
}

/// "1999-03-31" -> "1999", empty when the date is unknown.
func releaseYear(_ movie: Movie) -> String {
    // TODO: Lab 1, task 1. Return the first `releaseYearLength` characters of
    // `movie.releaseDate`, or "" when the date is shorter than that.
    // Hint: `String(text.prefix(count))`.
    if movie.releaseDate.count >= releaseYearLength {
        return String(movie.releaseDate.prefix(releaseYearLength))
    }
    return ""
}

/// 8.24 -> "8.2"
func formattedRating(_ movie: Movie) -> String {
    // TODO: Lab 1, task 1. Format `movie.voteAverage` with `ratingFormat`.
    // Hint: `String(format: ratingFormat, number)`.
    return String(format: ratingFormat, movie.voteAverage)
}

/// 8.24 -> "★ 8.2"
func ratingWithStar(_ movie: Movie) -> String {
    // TODO: Lab 1, task 2. `ratingStar`, a space, then `formattedRating(movie)`.
    return ratingStar + " " + formattedRating(movie)
}

/// "2014 · ★ 8.4", or "★ 8.4" when the release date is unknown.
func yearAndRating(_ movie: Movie) -> String {
    // TODO: Lab 1, task 2. Join `releaseYear(movie)` and `ratingWithStar(movie)`
    // with `textSeparator`. Leave the year and the separator out when the year is "".
    let year = releaseYear(movie)
    if year.isEmpty {
        return ratingWithStar(movie)
    }
    return year + textSeparator + ratingWithStar(movie)
}

/// Poster address on the TMDB image server, nil when the movie has no poster.
func posterURL(_ movie: Movie) -> URL? {
    let posterPath = movie.posterPath ?? ""
    if posterPath.isEmpty {
        return nil
    }
    return URL(string: tmdbPosterBaseURL + posterPath)
}

func hasPoster(_ movie: Movie) -> Bool {
    return posterURL(movie) != nil
}
