import Foundation

public struct XMLReaderOptions: OptionSet {
    public let rawValue: UInt8
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    static let processNamespaces = XMLReaderOptions(rawValue: 1 << 0)
    static let reportNamespacePrefixes = XMLReaderOptions(rawValue: 1 << 1)
    static let resolveExternalEntities = XMLReaderOptions(rawValue: 1 << 2)
}

public class XMLReader: NSObject {
    public static func dictionary(for xmlData: Data, options: XMLReaderOptions = []) throws -> NSDictionary {
        try XMLReader().object(with: xmlData, options: options)
    }
    public static func dictionary(for xmlString: String, options: XMLReaderOptions = []) throws -> NSDictionary {
        guard let data = xmlString.data(using: .utf8) else {
            throw NSError(domain: "No Data", code: -1)
        }
        return try dictionary(for: data, options: options)
    }
    
    private var dictionaryStack: NSMutableArray!
    private var textInProgress: String!
    private var errorPointer: Error?
    
    private func object(with data: Data, options: XMLReaderOptions) throws -> NSDictionary {
        dictionaryStack = [NSMutableDictionary()]
        textInProgress = ""
        errorPointer = nil
        
        let parser = XMLParser(data: data)
        
        parser.shouldProcessNamespaces = options.contains(.processNamespaces)
        parser.shouldReportNamespacePrefixes = options.contains(.reportNamespacePrefixes)
        parser.shouldResolveExternalEntities = options.contains(.resolveExternalEntities)
        
        parser.delegate = self
        if parser.parse(), let resultDict = dictionaryStack.firstObject as? NSDictionary {
            return resultDict
        }
        
        throw errorPointer ?? NSError(domain: "No Dictionary", code: -1)
    }
}

extension XMLReader: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        guard let parentDict = dictionaryStack.lastObject as? NSMutableDictionary else {
            return
        }
        let childDict = NSMutableDictionary(dictionary: attributeDict)
        if let existingValue = parentDict[elementName] {
            let array: NSMutableArray
            if existingValue is NSMutableArray {
                array = existingValue as! NSMutableArray
            } else {
                array = NSMutableArray(object: existingValue)
                parentDict[elementName] = array
            }
            array.add(childDict)
        } else {
            parentDict[elementName] = childDict
        }
        dictionaryStack.add(childDict)
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let dictInProgress = dictionaryStack.lastObject as? NSMutableDictionary else {
            return
        }
        if !textInProgress.isEmpty {
            dictInProgress["text"] = textInProgress.trimmingCharacters(in: .whitespacesAndNewlines)
            textInProgress = ""
        }
        dictionaryStack.removeLastObject()
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        textInProgress.append(string)
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        errorPointer = parseError
    }
}
