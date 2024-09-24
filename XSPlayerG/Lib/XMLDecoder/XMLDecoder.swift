import Foundation

public class XMLDecoder {
    private func json(from data: Data) throws -> Data {
        try JSONSerialization.data(withJSONObject: XMLReader.dictionary(for: data))
    }
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try JSONDecoder().decode(type, from: json(from: data))
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    public func decode<T>(_ type: T.Type, from data: Data, configuration: T.DecodingConfiguration) throws -> T where T : DecodableWithConfiguration {
        try JSONDecoder().decode(type, from: json(from: data), configuration: configuration)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    public func decode<T, C>(_ type: T.Type, from data: Data, configuration: C.Type) throws -> T where T : DecodableWithConfiguration, C : DecodingConfigurationProviding, T.DecodingConfiguration == C.DecodingConfiguration {
        try JSONDecoder().decode(type, from: json(from: data), configuration: configuration)
    }
}
