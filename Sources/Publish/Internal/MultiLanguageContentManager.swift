import Foundation
import Plot

fileprivate typealias SiteDescription = String

internal struct MultiLanguageContentManager {
    private static var multiLanguageContents: [SiteDescription: [String: [Language: Location]]] = [:]
    
    internal static func register<T: MultiLanguageWebsite>(_ location: Location, for site: T) {
        multiLanguageContents[
            String(describing: site),
            default: [:]
        ][
            (location as? Item<T>)?.metadata.alternateLinkIdentifier ?? location.path.string,
            default: [:]
        ][
            location.language!
        ] = location
    }
    
    internal static func location<T: MultiLanguageWebsite>(at path: Path, in language: Language, for site: T) -> Location? {
        multiLanguageContents[String(describing: site)]?[path.string]?[language]
    }
    
    internal static func alternateLinks<T: MultiLanguageWebsite>(for location: Location, in context: PublishingContext<T>) -> [Language: Path] {
        
        if let _ = location as? TagListPage {
            return Dictionary<Language, Path>(uniqueKeysWithValues: context.site.languages.map({
                ($0, "/\(context.site.tagListPath(in: $0))")
            }))
        }
        
        let locationKey = (location as? Item<T>)?.metadata.alternateLinkIdentifier ?? location.path.string
        
        let locations = multiLanguageContents[
            String(describing: context.site),
            default: [:]
        ][
            locationKey,
            default: [:]
        ]
        
        return Dictionary<Language, Path>(uniqueKeysWithValues: locations.keys.map({
            ($0, context.site.path(for: locations[$0]!))
            }))
    }
}

