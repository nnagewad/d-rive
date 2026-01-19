//
//  SupabaseService.swift
//  Purpose: Fetches data from Supabase backend
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-01-19.
//

import Foundation
import Supabase
import os.log

// MARK: - Supabase Response Models

struct SupabaseCountry: Codable, Identifiable, Sendable {
    let id: UUID
    let countryName: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case countryName = "country_name"
        case createdAt = "created_at"
    }
}

struct SupabaseCity: Codable, Identifiable, Sendable {
    let id: UUID
    let cityName: String
    let countryId: UUID?
    let createdAt: Date?

    // Joined data
    var country: SupabaseCountry?

    enum CodingKeys: String, CodingKey {
        case id
        case cityName = "city_name"
        case countryId = "country_id"
        case createdAt = "created_at"
        case country = "countries"
    }
}

struct SupabaseCurator: Codable, Identifiable, Sendable {
    let id: UUID
    let curatorName: String
    let curatorBio: String
    let imageUrl: String?
    let instagramHandle: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case curatorName = "curator_name"
        case curatorBio = "curator_bio"
        case imageUrl = "image_url"
        case instagramHandle = "instagram_handle"
        case createdAt = "created_at"
    }
}

struct SupabaseSpotCategory: Codable, Identifiable, Sendable {
    let id: UUID
    let categoryName: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryName = "category_name"
        case createdAt = "created_at"
    }
}

struct SupabaseCuratedList: Codable, Identifiable, Sendable {
    let id: UUID
    let listName: String
    let listDescription: String
    let imageUrl: String?
    let version: Int
    let lastUpdated: Date?
    let cityId: UUID?
    let curatorId: UUID?
    let createdAt: Date?

    // Joined data
    var city: SupabaseCity?
    var curator: SupabaseCurator?
    var spots: [SupabaseSpot]?

    enum CodingKeys: String, CodingKey {
        case id
        case listName = "list_name"
        case listDescription = "list_description"
        case imageUrl = "image_url"
        case version
        case lastUpdated = "last_updated"
        case cityId = "city_id"
        case curatorId = "curator_id"
        case createdAt = "created_at"
        case city = "cities"
        case curator = "curators"
        case spots
    }
}

struct SupabaseSpot: Codable, Identifiable, Sendable {
    let id: UUID
    let spotName: String
    let spotDescription: String
    let latitude: Double
    let longitude: Double
    let instagramHandle: String?
    let websiteUrl: String?
    let categoryId: UUID?
    let listId: UUID?
    let createdAt: Date?

    // Joined data
    var category: SupabaseSpotCategory?

    enum CodingKeys: String, CodingKey {
        case id
        case spotName = "spot_name"
        case spotDescription = "spot_description"
        case latitude
        case longitude
        case instagramHandle = "instagram_handle"
        case websiteUrl = "website_url"
        case categoryId = "category_id"
        case listId = "list_id"
        case createdAt = "created_at"
        case category = "spot_categories"
    }
}

// MARK: - Supabase Service

enum SupabaseServiceError: Error, LocalizedError {
    case notConfigured
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Check your credentials."
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        }
    }
}

final class SupabaseService: Sendable {

    static let shared = SupabaseService()

    private let logger = Logger(subsystem: "com.derive.app", category: "SupabaseService")

    private let client: SupabaseClient

    private init() {
        guard let secrets = SupabaseService.loadSecrets(),
              let urlString = secrets["SUPABASE_URL"] as? String,
              let key = secrets["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Missing or invalid Secrets.plist. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set.")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    private static func loadSecrets() -> [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dict
    }

    // MARK: - Fetch Countries

    func fetchCountries() async throws -> [SupabaseCountry] {
        do {
            let countries: [SupabaseCountry] = try await client
                .from("countries")
                .select()
                .order("country_name")
                .execute()
                .value

            logger.info("Fetched \(countries.count) countries")
            return countries
        } catch {
            logger.error("Failed to fetch countries: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Cities

    func fetchCities() async throws -> [SupabaseCity] {
        do {
            let cities: [SupabaseCity] = try await client
                .from("cities")
                .select("*, countries(*)")
                .order("city_name")
                .execute()
                .value

            logger.info("Fetched \(cities.count) cities")
            return cities
        } catch {
            logger.error("Failed to fetch cities: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Curators

    func fetchCurators() async throws -> [SupabaseCurator] {
        do {
            let curators: [SupabaseCurator] = try await client
                .from("curators")
                .select()
                .order("curator_name")
                .execute()
                .value

            logger.info("Fetched \(curators.count) curators")
            return curators
        } catch {
            logger.error("Failed to fetch curators: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Spot Categories

    func fetchSpotCategories() async throws -> [SupabaseSpotCategory] {
        do {
            let categories: [SupabaseSpotCategory] = try await client
                .from("spot_categories")
                .select()
                .order("category_name")
                .execute()
                .value

            logger.info("Fetched \(categories.count) spot categories")
            return categories
        } catch {
            logger.error("Failed to fetch spot categories: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Curated Lists

    func fetchCuratedLists() async throws -> [SupabaseCuratedList] {
        do {
            let lists: [SupabaseCuratedList] = try await client
                .from("curated_lists")
                .select("*, cities(*, countries(*)), curators(*)")
                .order("list_name")
                .execute()
                .value

            logger.info("Fetched \(lists.count) curated lists")
            return lists
        } catch {
            logger.error("Failed to fetch curated lists: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Curated Lists for a City

    func fetchCuratedLists(forCityId cityId: UUID) async throws -> [SupabaseCuratedList] {
        do {
            let lists: [SupabaseCuratedList] = try await client
                .from("curated_lists")
                .select("*, cities(*, countries(*)), curators(*)")
                .eq("city_id", value: cityId)
                .order("list_name")
                .execute()
                .value

            logger.info("Fetched \(lists.count) curated lists for city \(cityId)")
            return lists
        } catch {
            logger.error("Failed to fetch curated lists for city: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Spots

    func fetchSpots() async throws -> [SupabaseSpot] {
        do {
            let spots: [SupabaseSpot] = try await client
                .from("spots")
                .select("*, spot_categories(*)")
                .order("spot_name")
                .execute()
                .value

            logger.info("Fetched \(spots.count) spots")
            return spots
        } catch {
            logger.error("Failed to fetch spots: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Spots for a List

    func fetchSpots(forListId listId: UUID) async throws -> [SupabaseSpot] {
        do {
            let spots: [SupabaseSpot] = try await client
                .from("spots")
                .select("*, spot_categories(*)")
                .eq("list_id", value: listId)
                .order("spot_name")
                .execute()
                .value

            logger.info("Fetched \(spots.count) spots for list \(listId)")
            return spots
        } catch {
            logger.error("Failed to fetch spots for list: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }

    // MARK: - Fetch Complete List with Spots

    func fetchCompleteList(listId: UUID) async throws -> SupabaseCuratedList {
        do {
            let list: SupabaseCuratedList = try await client
                .from("curated_lists")
                .select("*, cities(*, countries(*)), curators(*), spots(*, spot_categories(*))")
                .eq("id", value: listId)
                .single()
                .execute()
                .value

            logger.info("Fetched complete list: \(list.listName) with \(list.spots?.count ?? 0) spots")
            return list
        } catch {
            logger.error("Failed to fetch complete list: \(error.localizedDescription)")
            throw SupabaseServiceError.fetchFailed(error)
        }
    }
}
