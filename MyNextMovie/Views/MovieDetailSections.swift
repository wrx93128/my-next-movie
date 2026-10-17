import SwiftUI

private let trailerButtonHeight: CGFloat = 44
private let castPhotoSize: CGFloat = 72
private let castItemWidth: CGFloat = 80
private let providerLogoSize: CGFloat = 48
private let providerItemWidth: CGFloat = 72
private let recommendationCardWidth: CGFloat = 140

struct MovieDetailSections: View {
    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: spacingExtraLarge) {
            trailerSection
            castSection
            watchProvidersSection
            recommendationsSection
        }
    }

    @ViewBuilder
    private var trailerSection: some View {
        if let url = trailerURL(details) {
            Link(destination: url) {
                Label("Watch Trailer", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: trailerButtonHeight)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var castSection: some View {
        let cast = Array(details.credits.cast.prefix(15))
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: spacingMedium) {
                Text("Cast")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacingMedium) {
                        ForEach(cast) { member in
                            CastMemberView(member: member)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    @ViewBuilder
    private var watchProvidersSection: some View {
        let countryProviders = watchProviders(details)
        if hasWatchProviders(countryProviders) {
            VStack(alignment: .leading, spacing: spacingMedium) {
                Text("Where to Watch")
                    .font(.headline)

                if let flatrate = countryProviders.flatrate, !flatrate.isEmpty {
                    ProviderGroup(title: "Stream", providers: flatrate)
                }
                if let rent = countryProviders.rent, !rent.isEmpty {
                    ProviderGroup(title: "Rent", providers: rent)
                }
                if let buy = countryProviders.buy, !buy.isEmpty {
                    ProviderGroup(title: "Buy", providers: buy)
                }

                Text("Streaming data from JustWatch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        let movies = details.recommendations.results
        if !movies.isEmpty {
            VStack(alignment: .leading, spacing: spacingMedium) {
                Text("More Like This")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacingMedium) {
                        ForEach(movies) { movie in
                            NavigationLink(value: movie) {
                                MovieCardView(movie: movie)
                                    .frame(width: recommendationCardWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct CastMemberView: View {
    let member: CastMember

    var body: some View {
        VStack(spacing: spacingExtraSmall) {
            photo
            Text(member.name)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(member.character)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: castItemWidth)
    }

    private var photo: some View {
        Group {
            if let url = profileURL(member) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        fallbackPhoto
                    @unknown default:
                        fallbackPhoto
                    }
                }
            } else {
                fallbackPhoto
            }
        }
        .frame(width: castPhotoSize, height: castPhotoSize)
        .clipShape(Circle())
    }

    private var fallbackPhoto: some View {
        Circle()
            .fill(Color(.secondarySystemBackground))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

private struct ProviderGroup: View {
    let title: String
    let providers: [WatchProvider]

    var body: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacingMedium) {
                    ForEach(providers) { provider in
                        ProviderView(provider: provider)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}

private struct ProviderView: View {
    let provider: WatchProvider

    var body: some View {
        VStack(spacing: spacingExtraSmall) {
            logo
            Text(provider.providerName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: providerItemWidth)
    }

    private var logo: some View {
        Group {
            if let url = logoURL(provider) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure, .empty:
                        fallbackLogo
                    @unknown default:
                        fallbackLogo
                    }
                }
            } else {
                fallbackLogo
            }
        }
        .frame(width: providerLogoSize, height: providerLogoSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fallbackLogo: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.secondarySystemBackground))
            .overlay {
                Image(systemName: symbolNameMovies)
                    .foregroundStyle(.secondary)
            }
    }
}
