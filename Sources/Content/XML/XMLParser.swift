//
//  SWXMLHash.swift
//
//  Copyright (c) 2014 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Venice
import Core

public enum XMLParserError : Error {
    case invalidXML
}

fileprivate class ParserStream : InputStream {
    private let stream: Readable
    private let deadline: Deadline
    private let buffer: UnsafeMutableRawBufferPointer
    private var lastError: Error?
    private var finished = false
    
    fileprivate init(stream: Readable, deadline: Deadline, bufferSize: Int = 4096) {
        self.stream = stream
        self.deadline = deadline
        self.buffer = UnsafeMutableRawBufferPointer.allocate(count: bufferSize)
        super.init(data: Data())
    }
    
    deinit {
        buffer.deallocate()
    }
    
    #if os(macOS)
    fileprivate override var streamError: Error? {
        return lastError
    }
    #else
    fileprivate override var streamError: NSError? {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: lastError.map({ String(describing: $0) }) ?? ""
        ]
        
        let error = NSError(
            domain: "XMLParserError",
            code: 0,
            userInfo: userInfo
        )
        
        return error
    }
    #endif
    
    fileprivate override func open() {}
    fileprivate override func close() {}
    
    fileprivate override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength count: Int) -> Int {
        let buffer = UnsafeMutableRawBufferPointer(start: buffer, count: count)
        
        do {
            let read = try stream.read(buffer, deadline: deadline)
            
            if read.isEmpty {
                finished = true
            }
            
            return read.count
        } catch {
            lastError = error
            return -1
        }
    }
    
    fileprivate override func getBuffer(
        _ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
        length count: UnsafeMutablePointer<Int>
    ) -> Bool {
        buffer.pointee = self.buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
        count.pointee = self.buffer.count
        return true
    }
    
    fileprivate override var hasBytesAvailable: Bool {
        return !finished
    }
}

public class XMLParser : NSObject, XMLParserDelegate {
    var stack = Stack()
    
    public static func parse(
        _ stream: Readable,
        bufferSize: Int = 4096,
        deadline: Deadline
    ) throws -> XML {
        let xmlParser = XMLParser()
        
        let parseStream = ParserStream(stream: stream, deadline: deadline)
        let parser = Foundation.XMLParser(stream: parseStream)
        parser.delegate = xmlParser
        
        guard parser.parse() else {
            throw parser.parserError ?? XMLParserError.invalidXML
        }
        
        guard let root = xmlParser.stack.root else {
            throw XMLParserError.invalidXML
        }
        
        return root
    }
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didStartElement name: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        let element = XML(name: name, attributes: attributes)
        
        if !stack.isEmpty {
            stack.top().addElement(element)
        }
        
        stack.push(element)
    }
    
    public func parser(_ parser: Foundation.XMLParser, foundCharacters content: String) {
        stack.top().addContent(content)
    }
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        stack.drop()
    }
}

struct Stack {
    var root: XML?
    private var items: [XML] = []
    
    mutating func push(_ item: XML) {
        if root == nil {
            root = item
        }
        
        items.append(item)
    }
    
    mutating func drop() {
        items.removeLast()
    }
    
    mutating func removeAll() {
        items.removeAll(keepingCapacity: false)
    }
    
    func top() -> XML {
        return items[items.count - 1]
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
}

#if os(Linux)
extension XMLParserDelegate {
    public func parserDidStartDocument(_ parser: Foundation.XMLParser) {}
    public func parserDidEndDocument(_ parser: Foundation.XMLParser) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundNotationDeclarationWithName name: String,
        publicID: String?,
        systemID: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundUnparsedEntityDeclarationWithName name: String,
        publicID: String?,
        systemID: String?,
        notationName: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundAttributeDeclarationWithName attributeName: String,
        forElement elementName: String,
        type: String?,
        defaultValue: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundElementDeclarationWithName elementName: String,
        model: String
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundInternalEntityDeclarationWithName name: String,
        value: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundExternalEntityDeclarationWithName name: String,
        publicID: String?,
        systemID: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String]
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didStartMappingPrefix prefix: String,
        toURI namespaceURI: String
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        didEndMappingPrefix prefix: String
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundCharacters string: String
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundIgnorableWhitespace whitespaceString: String
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        foundProcessingInstructionWithTarget target: String,
        data: String?
    ) {}
    
    public func parser(_ parser: Foundation.XMLParser, foundComment comment: String) {}
    public func parser(_ parser: Foundation.XMLParser, foundCDATA CDATABlock: Data) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        resolveExternalEntityName name: String,
        systemID: String?
    ) -> Data? { return nil }
    
    public func parser(
        _ parser: Foundation.XMLParser,
        parseErrorOccurred parseError: NSError
    ) {}
    
    public func parser(
        _ parser: Foundation.XMLParser,
        validationErrorOccurred validationError: NSError
    ) {}
}
#endif
