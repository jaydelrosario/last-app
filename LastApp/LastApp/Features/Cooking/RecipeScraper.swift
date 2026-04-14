// LastApp/Features/Cooking/RecipeScraper.swift
import Foundation

struct ScrapedRecipe {
    var title: String = ""
    var description: String = ""
    var prepMinutes: Int = 0
    var cookMinutes: Int = 0
    var servings: Int = 2
    var ingredients: [ScrapedIngredient] = []
    var steps: [String] = []
}

struct ScrapedIngredient {
    var amount: String
    var unit: String
    var name: String
}

enum ScraperError: LocalizedError {
    case invalidURL
    case fetchFailed
    case noRecipeFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: "That doesn't look like a valid URL."
        case .fetchFailed: "Couldn't load the page. Check your connection."
        case .noRecipeFound: "No recipe data found on that page. The site may not be supported."
        }
    }
}

struct RecipeScraper {

    static func scrape(urlString: String) async throws -> ScrapedRecipe {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
              url.scheme == "https" || url.scheme == "http" else {
            throw ScraperError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ScraperError.fetchFailed
        }

        guard let recipe = extractRecipe(from: html) else {
            throw ScraperError.noRecipeFound
        }
        return recipe
    }

    // MARK: - JSON-LD extraction

    private static func extractRecipe(from html: String) -> ScrapedRecipe? {
        // Find all <script type="application/ld+json"> blocks
        var searchRange = html.startIndex..<html.endIndex
        let openTag = "application/ld+json"

        while let scriptStart = html.range(of: openTag, range: searchRange) {
            // Find the closing > of the opening tag
            guard let tagClose = html.range(of: ">", range: scriptStart.upperBound..<html.endIndex),
                  let scriptEnd = html.range(of: "</script>", range: tagClose.upperBound..<html.endIndex) else {
                break
            }

            let jsonString = String(html[tagClose.upperBound..<scriptEnd.lowerBound])
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) {
                if let recipe = findRecipeObject(in: json) {
                    return parseRecipe(from: recipe)
                }
            }

            searchRange = scriptEnd.upperBound..<html.endIndex
        }
        return nil
    }

    /// Recursively search for a Recipe type in the JSON structure
    private static func findRecipeObject(in json: Any) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            let type_ = dict["@type"]
            if isRecipeType(type_) { return dict }
            // Check @graph array
            if let graph = dict["@graph"] as? [[String: Any]] {
                for item in graph {
                    if let found = findRecipeObject(in: item) { return found }
                }
            }
        }
        if let array = json as? [[String: Any]] {
            for item in array {
                if let found = findRecipeObject(in: item) { return found }
            }
        }
        return nil
    }

    private static func isRecipeType(_ value: Any?) -> Bool {
        if let str = value as? String { return str == "Recipe" }
        if let arr = value as? [String] { return arr.contains("Recipe") }
        return false
    }

    // MARK: - Parsing

    private static func parseRecipe(from dict: [String: Any]) -> ScrapedRecipe {
        var recipe = ScrapedRecipe()

        recipe.title = string(dict["name"]) ?? ""
        recipe.description = string(dict["description"]) ?? ""
        recipe.prepMinutes = parseDuration(dict["prepTime"])
        recipe.cookMinutes = parseDuration(dict["cookTime"])
        recipe.servings = parseServings(dict["recipeYield"])
        recipe.ingredients = parseIngredients(dict["recipeIngredient"])
        recipe.steps = parseInstructions(dict["recipeInstructions"])

        return recipe
    }

    private static func string(_ value: Any?) -> String? {
        (value as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    /// ISO 8601 duration → minutes (e.g. "PT1H30M" → 90, "PT45M" → 45)
    private static func parseDuration(_ value: Any?) -> Int {
        guard let str = value as? String else { return 0 }
        var total = 0
        if let h = str.range(of: #"(\d+)H"#, options: .regularExpression) {
            total += (Int(str[h].filter(\.isNumber)) ?? 0) * 60
        }
        if let m = str.range(of: #"(\d+)M"#, options: .regularExpression) {
            total += Int(str[m].filter(\.isNumber)) ?? 0
        }
        return total
    }

    private static func parseServings(_ value: Any?) -> Int {
        if let n = value as? Int { return max(1, n) }
        if let str = value as? String, let n = Int(str.components(separatedBy: .whitespaces).first ?? "") {
            return max(1, n)
        }
        if let arr = value as? [String], let first = arr.first,
           let n = Int(first.components(separatedBy: .whitespaces).first ?? "") {
            return max(1, n)
        }
        return 2
    }

    private static func parseIngredients(_ value: Any?) -> [ScrapedIngredient] {
        guard let arr = value as? [String] else { return [] }
        return arr.compactMap { parseIngredientLine($0) }
    }

    /// Split "1 1/2 cups all-purpose flour, sifted" → amount, unit, name
    private static func parseIngredientLine(_ raw: String) -> ScrapedIngredient? {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty else { return nil }

        let units: Set<String> = [
            "cup","cups","tablespoon","tablespoons","tbsp","tsp","teaspoon","teaspoons",
            "ounce","ounces","oz","pound","pounds","lb","lbs","gram","grams","g",
            "kilogram","kilograms","kg","ml","milliliter","milliliters","liter","liters","l",
            "pinch","dash","clove","cloves","can","cans","package","packages","bunch",
            "slice","slices","piece","pieces","sprig","sprigs","handful"
        ]

        let tokens = line.components(separatedBy: .whitespaces)
        var idx = 0

        // Amount: one or two numeric tokens (e.g. "1" "1/2" or "1½")
        var amountTokens: [String] = []
        while idx < tokens.count {
            let t = tokens[idx]
            if isNumeric(t) {
                amountTokens.append(t)
                idx += 1
            } else { break }
        }
        let amount = amountTokens.joined(separator: " ")

        // Unit
        var unit = ""
        if idx < tokens.count && units.contains(tokens[idx].lowercased().trimmingCharacters(in: CharacterSet.letters.inverted)) {
            unit = tokens[idx]
            idx += 1
        }

        let name = tokens[idx...].joined(separator: " ").trimmingCharacters(in: .whitespaces)

        return ScrapedIngredient(
            amount: amount,
            unit: unit,
            name: name.isEmpty ? line : name
        )
    }

    private static func isNumeric(_ token: String) -> Bool {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "½⅓⅔¼¾⅛⅜⅝⅞"))
        if clean.isEmpty { return true }
        if Double(clean) != nil { return true }
        let parts = clean.split(separator: "/")
        if parts.count == 2, Int(parts[0]) != nil, Int(parts[1]) != nil { return true }
        return false
    }

    private static func parseInstructions(_ value: Any?) -> [String] {
        guard let value else { return [] }

        // Plain array of strings
        if let strings = value as? [String] {
            return strings.filter { !$0.isEmpty }
        }

        // Array of HowToStep / HowToSection objects
        if let objects = value as? [[String: Any]] {
            var steps: [String] = []
            for obj in objects {
                let type_ = obj["@type"] as? String ?? ""
                if type_ == "HowToSection", let items = obj["itemListElement"] as? [[String: Any]] {
                    steps += items.compactMap { $0["text"] as? String }.filter { !$0.isEmpty }
                } else if let text = obj["text"] as? String, !text.isEmpty {
                    steps.append(text)
                } else if let name = obj["name"] as? String, !name.isEmpty {
                    steps.append(name)
                }
            }
            return steps
        }

        // Single string
        if let str = value as? String, !str.isEmpty {
            return [str]
        }
        return []
    }
}
