import Foundation
import Testing

@testable import MyNextMovie

private let matrixDetailsJSON = """
    {
      "id": 603,
      "tagline": "Welcome to the Real World.",
      "runtime": 136,
      "credits": {
        "cast": [
          {
            "id": 6384,
            "name": "Keanu Reeves",
            "character": "Neo",
            "profile_path": "/8RZL.jpg"
          },
          {
            "id": 133,
            "name": "Actor Without Photo",
            "character": "Extra",
            "profile_path": null
          }
        ],
        "crew": [
          {
            "id": 9340,
            "name": "Lana Wachowski",
            "job": "Director"
          },
          {
            "id": 9340,
            "name": "Lana Wachowski",
            "job": "Director"
          },
          {
            "id": 9339,
            "name": "Lilly Wachowski",
            "job": "Director"
          }
        ]
      },
      "videos": {
        "results": [
          {
            "key": "unofficialKey",
            "site": "YouTube",
            "type": "Trailer",
            "official": false
          },
          {
            "key": "vKQi3bBA1y8",
            "site": "YouTube",
            "type": "Trailer",
            "official": true
          }
        ]
      },
      "release_dates": {
        "results": [
          {
            "iso_3166_1": "PL",
            "release_dates": [
              {
                "certification": ""
              },
              {
                "certification": "16"
              }
            ]
          },
          {
            "iso_3166_1": "US",
            "release_dates": [
              {
                "certification": "R"
              }
            ]
          }
        ]
      },
      "watch/providers": {
        "results": {
          "PL": {
            "link": "https://www.themoviedb.org/movie/603-the-matrix/watch?locale=PL",
            "flatrate": [
              {
                "provider_id": 119,
                "provider_name": "Amazon Prime Video",
                "logo_path": "/gMZd.png"
              }
            ],
            "rent": [
              {
                "provider_id": 3,
                "provider_name": "Google Play Movies",
                "logo_path": "/tbEd.png"
              }
            ]
          }
        }
      },
      "recommendations": {
        "results": [
          {
            "id": 604,
            "title": "The Matrix Reloaded",
            "overview": "Six months after the events depicted in The Matrix...",
            "release_date": "2003-05-15",
            "poster_path": "/9TGHD.jpg",
            "vote_average": 7.0,
            "genre_ids": [28, 878]
          }
        ]
      }
    }
    """

private let announcedMovieJSON = """
    {
      "id": 999,
      "tagline": "",
      "runtime": null,
      "credits": {
        "cast": [],
        "crew": []
      },
      "videos": {
        "results": []
      },
      "release_dates": {
        "results": []
      },
      "watch/providers": {
        "results": {}
      },
      "recommendations": {
        "results": []
      }
    }
    """

@MainActor
struct MovieDetailsDecodingTests {
    @Test func decodesTaglineAndRuntime() throws {
        let data = matrixDetailsJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)

        #expect(details.id == 603)
        #expect(details.tagline == "Welcome to the Real World.")
        #expect(details.runtime == 136)
    }

    @Test func decodesCastWithAndWithoutPhoto() throws {
        let data = matrixDetailsJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)

        #expect(details.credits.cast.count == 2)
        #expect(details.credits.cast[0].profilePath == "/8RZL.jpg")
        #expect(details.credits.cast[1].profilePath == nil)
    }

    @Test func decodesWatchProvidersUnderSlashKey() throws {
        let data = matrixDetailsJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)
        let plProviders = details.watchProviders.results["PL"]

        #expect(plProviders != nil)
        #expect(plProviders?.flatrate?.count == 1)
        #expect(plProviders?.rent?.count == 1)
        #expect(plProviders?.buy == nil)
    }

    @Test func decodesCountryCodeOfReleaseDates() throws {
        let data = matrixDetailsJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)

        let plRelease = details.releaseDates.results.first { $0.countryCode == "PL" }
        #expect(plRelease != nil)
        #expect(plRelease?.countryCode == "PL")
    }

    @Test func decodesRecommendationsAsMovies() throws {
        let data = matrixDetailsJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)

        #expect(details.recommendations.results.count == 1)
        let firstRecommendation = details.recommendations.results[0]
        #expect(firstRecommendation.id == 604)
        #expect(firstRecommendation.title == "The Matrix Reloaded")
    }

    @Test func decodesAnnouncedMovieWithoutRuntime() throws {
        let data = announcedMovieJSON.data(using: .utf8)!
        let details = try decodeTMDBMovieDetails(data)

        #expect(details.runtime == nil)
        #expect(formattedRuntime(details) == "")
        let providers = watchProviders(details, regionCode: "PL")
        #expect(!hasWatchProviders(providers))
    }
}

@MainActor
struct MovieDetailsTests {
    @Test func runtimeInHoursAndMinutes() {
        let details136 = makeMovieDetails(runtime: 136)
        #expect(formattedRuntime(details136) == "2h 16m")

        let details120 = makeMovieDetails(runtime: 120)
        #expect(formattedRuntime(details120) == "2h 0m")
    }

    @Test func runtimeUnderAnHourHasOnlyMinutes() {
        let details45 = makeMovieDetails(runtime: 45)
        #expect(formattedRuntime(details45) == "45m")
    }

    @Test func runtimeIsEmptyWhenUnknown() {
        let detailsNil = makeMovieDetails(runtime: nil)
        #expect(formattedRuntime(detailsNil) == "")

        let details0 = makeMovieDetails(runtime: 0)
        #expect(formattedRuntime(details0) == "")
    }

    @Test func directorsAreListedOnceEach() {
        let crew = [
            CrewMember(id: 1, name: "Lana Wachowski", job: "Director"),
            CrewMember(id: 1, name: "Lana Wachowski", job: "Director"),
            CrewMember(id: 2, name: "Lilly Wachowski", job: "Director"),
            CrewMember(id: 3, name: "Joel Silver", job: "Producer")
        ]
        let details = makeMovieDetails(crew: crew)
        #expect(directorNames(details) == "Lana Wachowski, Lilly Wachowski")
    }

    @Test func directorsAreEmptyWithoutDirector() {
        let crew = [
            CrewMember(id: 3, name: "Joel Silver", job: "Producer")
        ]
        let details = makeMovieDetails(crew: crew)
        #expect(directorNames(details) == "")
    }

    @Test func certificationSkipsEmptyOnes() {
        let releaseDates = [
            CountryReleaseDates(
                countryCode: "PL",
                releaseDates: [ReleaseDate(certification: ""), ReleaseDate(certification: "16")]
            ),
            CountryReleaseDates(
                countryCode: "US",
                releaseDates: [ReleaseDate(certification: "R")]
            )
        ]
        let details = makeMovieDetails(releaseDates: releaseDates)
        #expect(ageCertification(details, regionCode: "PL") == "16")
        #expect(ageCertification(details, regionCode: "US") == "R")
    }

    @Test func certificationIsEmptyForOtherCountry() {
        let releaseDates = [
            CountryReleaseDates(
                countryCode: "US",
                releaseDates: [ReleaseDate(certification: "R")]
            )
        ]
        let details = makeMovieDetails(releaseDates: releaseDates)
        #expect(ageCertification(details, regionCode: "DE") == "")
    }

    @Test func officialTrailerWins() {
        let videos = [
            Video(key: "unofficial", site: "YouTube", type: "Trailer", official: false),
            Video(key: "official", site: "YouTube", type: "Trailer", official: true)
        ]
        let details = makeMovieDetails(videos: videos)
        #expect(trailerKey(details) == "official")
    }

    @Test func unofficialTrailerWhenNoOfficial() {
        let videos = [
            Video(key: "unofficial", site: "YouTube", type: "Trailer", official: false)
        ]
        let details = makeMovieDetails(videos: videos)
        #expect(trailerKey(details) == "unofficial")
    }

    @Test func trailerOnOtherSiteIsSkipped() {
        let videos = [
            Video(key: "vimeoKey", site: "Vimeo", type: "Trailer", official: true)
        ]
        let details = makeMovieDetails(videos: videos)
        #expect(trailerKey(details) == "")
    }

    @Test func trailerURLPointsToYouTube() {
        let videos = [
            Video(key: "vKQi3bBA1y8", site: "YouTube", type: "Trailer", official: true)
        ]
        let details = makeMovieDetails(videos: videos)
        #expect(trailerURL(details) == URL(string: "https://www.youtube.com/watch?v=vKQi3bBA1y8"))
    }

    @Test func factsLineAddsRuntimeAndCertification() {
        let movie = makeMovie(releaseDate: "1999-03-31", voteAverage: 8.2)
        let releaseDates = [
            CountryReleaseDates(countryCode: "PL", releaseDates: [ReleaseDate(certification: "16")])
        ]
        let details = makeMovieDetails(runtime: 136, releaseDates: releaseDates)
        #expect(movieFactsLine(movie, details, regionCode: "PL") == "1999 · ★ 8.2 · 2h 16m · 16")
    }

    @Test func factsLineBeforeDetailsLoad() {
        let movie = makeMovie(releaseDate: "1999-03-31", voteAverage: 8.2)
        #expect(movieFactsLine(movie, emptyMovieDetails) == "1999 · ★ 8.2")
    }

    @Test func profileURLIsNilWithoutPhoto() {
        let withPhoto = CastMember(id: 1, name: "Actor", character: "Role", profilePath: "/photo.jpg")
        let withoutPhoto = CastMember(id: 2, name: "Actor", character: "Role", profilePath: nil)

        #expect(profileURL(withPhoto) == URL(string: "\(tmdbProfileBaseURL)/photo.jpg"))
        #expect(profileURL(withoutPhoto) == nil)
    }
}

func makeMovieDetails(
    id: Int = 1,
    tagline: String = "",
    runtime: Int? = nil,
    cast: [CastMember] = [],
    crew: [CrewMember] = [],
    videos: [Video] = [],
    releaseDates: [CountryReleaseDates] = [],
    watchProviders: [String: CountryWatchProviders] = [:],
    recommendations: [Movie] = []
) -> MovieDetails {
    MovieDetails(
        id: id,
        tagline: tagline,
        runtime: runtime,
        credits: Credits(cast: cast, crew: crew),
        videos: VideoList(results: videos),
        releaseDates: ReleaseDateList(results: releaseDates),
        watchProviders: WatchProviderList(results: watchProviders),
        recommendations: TMDBMoviePage(results: recommendations)
    )
}
