import Foundation

let tmdbProfileBaseURL = "https://image.tmdb.org/t/p/w185"
let tmdbLogoBaseURL = "https://image.tmdb.org/t/p/w92"
let youtubeWatchBaseURL = "https://www.youtube.com/watch?v="

nonisolated struct MovieDetails: Identifiable, Decodable {
    let id: Int
    let tagline: String
    let runtime: Int?
    let credits: Credits
    let videos: VideoList
    let releaseDates: ReleaseDateList
    let watchProviders: WatchProviderList
    let recommendations: TMDBMoviePage

    enum CodingKeys: String, CodingKey {
        case id
        case tagline
        case runtime
        case credits
        case videos
        case releaseDates
        case watchProviders = "watch/providers"
        case recommendations
    }
}

nonisolated struct Credits: Decodable {
    let cast: [CastMember]
    let crew: [CrewMember]
}

nonisolated struct CastMember: Identifiable, Decodable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
}

nonisolated struct CrewMember: Decodable {
    let id: Int
    let name: String
    let job: String
}

nonisolated struct VideoList: Decodable {
    let results: [Video]
}

nonisolated struct Video: Decodable {
    let key: String
    let site: String
    let type: String
    let official: Bool
}

nonisolated struct ReleaseDateList: Decodable {
    let results: [CountryReleaseDates]
}

nonisolated struct CountryReleaseDates: Decodable {
    let countryCode: String
    let releaseDates: [ReleaseDate]

    enum CodingKeys: String, CodingKey {
        case countryCode = "iso31661"
        case releaseDates
    }
}

nonisolated struct ReleaseDate: Decodable {
    let certification: String
}

nonisolated struct WatchProviderList: Decodable {
    let results: [String: CountryWatchProviders]
}

nonisolated struct CountryWatchProviders: Decodable {
    let link: String
    let flatrate: [WatchProvider]?
    let rent: [WatchProvider]?
    let buy: [WatchProvider]?
}

nonisolated struct WatchProvider: Identifiable, Decodable {
    let providerId: Int
    let providerName: String
    let logoPath: String?

    var id: Int {
        return providerId
    }
}

let emptyMovieDetails = MovieDetails(
    id: 0,
    tagline: "",
    runtime: nil,
    credits: Credits(cast: [], crew: []),
    videos: VideoList(results: []),
    releaseDates: ReleaseDateList(results: []),
    watchProviders: WatchProviderList(results: [:]),
    recommendations: TMDBMoviePage(results: [])
)

let noWatchProviders = CountryWatchProviders(
    link: "",
    flatrate: nil,
    rent: nil,
    buy: nil
)

let watchRegionCode = Locale.current.region?.identifier ?? "PL"

func formattedRuntime(_ details: MovieDetails) -> String {
    guard let runtime = details.runtime, runtime > 0 else {
        return ""
    }
    let hours = runtime / 60
    let minutes = runtime % 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

func directorNames(_ details: MovieDetails) -> String {
    var directors: [String] = []
    for member in details.credits.crew {
        if member.job == "Director" && !directors.contains(member.name) {
            directors.append(member.name)
        }
    }
    return directors.joined(separator: ", ")
}

func ageCertification(_ details: MovieDetails, regionCode: String) -> String {
    guard let country = details.releaseDates.results.first(where: { $0.countryCode == regionCode })
    else {
        return ""
    }
    for releaseDate in country.releaseDates {
        if !releaseDate.certification.isEmpty {
            return releaseDate.certification
        }
    }
    return ""
}

func trailerKey(_ details: MovieDetails) -> String {
    let trailers = details.videos.results.filter { $0.site == "YouTube" && $0.type == "Trailer" }
    if let official = trailers.first(where: { $0.official }) {
        return official.key
    }
    return trailers.first?.key ?? ""
}

func trailerURL(_ details: MovieDetails) -> URL? {
    let key = trailerKey(details)
    guard !key.isEmpty else { return nil }
    return URL(string: "\(youtubeWatchBaseURL)\(key)")
}

func hasTrailer(_ details: MovieDetails) -> Bool {
    return trailerURL(details) != nil
}

func movieFactsLine(_ movie: Movie, _ details: MovieDetails, regionCode: String = watchRegionCode) -> String {
    var parts: [String] = []
    let base = yearAndRating(movie)
    if !base.isEmpty {
        parts.append(base)
    }
    let runtimeText = formattedRuntime(details)
    if !runtimeText.isEmpty {
        parts.append(runtimeText)
    }
    let cert = ageCertification(details, regionCode: regionCode)
    if !cert.isEmpty {
        parts.append(cert)
    }
    return parts.joined(separator: textSeparator)
}

func watchProviders(_ details: MovieDetails, regionCode: String = watchRegionCode) -> CountryWatchProviders {
    return details.watchProviders.results[regionCode] ?? noWatchProviders
}

func hasWatchProviders(_ countryProviders: CountryWatchProviders) -> Bool {
    let hasFlatrate = !(countryProviders.flatrate?.isEmpty ?? true)
    let hasRent = !(countryProviders.rent?.isEmpty ?? true)
    let hasBuy = !(countryProviders.buy?.isEmpty ?? true)
    return hasFlatrate || hasRent || hasBuy
}

func profileURL(_ castMember: CastMember) -> URL? {
    guard let profilePath = castMember.profilePath, !profilePath.isEmpty else {
        return nil
    }
    return URL(string: "\(tmdbProfileBaseURL)\(profilePath)")
}

func logoURL(_ provider: WatchProvider) -> URL? {
    guard let logoPath = provider.logoPath, !logoPath.isEmpty else {
        return nil
    }
    return URL(string: "\(tmdbLogoBaseURL)\(logoPath)")
}
