//
//  Misc+.swift
//  iOSCodeRepo
//
//  Created by Yanun on 2024/8/29.
//

import Foundation
import UIKit

extension Array where Element == UIImage {
  func collage(size: CGSize) -> UIImage {
    let rows = self.count < 3 ? 1 : 2
    let columns = Int(round(Double(self.count) / Double(rows)))
    let tileSize = CGSize(width: round(size.width / CGFloat(columns)),
                          height: round(size.height / CGFloat(rows)))

    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    UIColor.white.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))

    for (index, image) in self.enumerated() {
      image.scaled(tileSize).draw(at: CGPoint(
        x: CGFloat(index % columns) * tileSize.width,
        y: CGFloat(index / columns) * tileSize.height
      ))
    }

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image ?? UIImage()
  }
}

extension UIImage {
  func scaled(_ newSize: CGSize) -> UIImage {
    guard size != newSize else {
      return self
    }

    let ratio = max(newSize.width / size.width, newSize.height / size.height)
    let width = size.width * ratio
    let height = size.height * ratio

    let scaledRect = CGRect(
      x: (newSize.width - width) / 2.0,
      y: (newSize.height - height) / 2.0,
      width: width, height: height)

    UIGraphicsBeginImageContextWithOptions(scaledRect.size, false, 0.0);
    defer { UIGraphicsEndImageContext() }

    draw(in: scaledRect)

    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }
}


public extension DispatchSource {
  class func timer(interval: Double, queue: DispatchQueue, handler: @escaping (DispatchSourceTimer) -> Void) -> DispatchSourceTimer {
    let source = DispatchSource.makeTimerSource(queue: queue)
    source.setEventHandler {
        handler(source)
    }
    source.schedule(deadline: .now(), repeating: interval, leeway: .nanoseconds(0))
    source.resume()
    return source
  }
}


extension Decodable where Self: Identifiable {
    
    mutating func loadFromCache(using decoder: JSONDecoder = .init()) throws {
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let typeName = String(describing: Self.self)
        let fileName = "\(typeName)-\(id).cache"
        let fileURL = folderURLs[0].appendingPathComponent(fileName)
        let data = try Data(contentsOf: fileURL)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
}

extension Encodable where Self: Identifiable {
    // We also take this opportunity to parameterize our JSON
    // encoder, to enable the users of our new API to pass in
    // a custom encoder, and to make our method's dependencies
    // more clear:
    func cacheOnDisk(using encoder: JSONEncoder = .init()) throws {
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        // Rather than hard-coding a specific type's name here,
        // we instead dynamically resolve a description of the
        // type that our method is currently being called on:
        let typeName = String(describing: Self.self)
        let fileName = "\(typeName)-\(id).cache"
        let fileURL = folderURLs[0].appendingPathComponent(fileName)
        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }
}

extension String {
    func tokenize(using handlers: [Character : (String) -> Void]) {
        // We no longer have to maintain an array of symbols,
        // but we do need to keep track of both any currently
        // parsed symbol, as well as which handler its for.
        var parsingData: (symbol: String, handler: (String) -> Void)?

        func parse(_ character: Character) {
            if var data = parsingData {
                guard character.isLetter else {
                    if !data.symbol.isEmpty {
                        data.handler(data.symbol)
                    }

                    parsingData = nil
                    return parse(character)
                }

                data.symbol.append(character)
                parsingData = data
            } else {
                // If we have a handler for a given character,
                // then we’ll parse it.
                guard let handler = handlers[character] else {
                    return
                }

                parsingData = ("", handler)
            }
        }

        forEach(parse)

        if let lastData = parsingData, !lastData.symbol.isEmpty {
            lastData.handler(lastData.symbol)
        }
    }
}

protocol AnyDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: AnyDecoder {}
extension PropertyListDecoder: AnyDecoder {}

extension Data {
    func decoded<T: Decodable>(using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: self)
    }
}

protocol AnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: AnyEncoder {}
extension PropertyListEncoder: AnyEncoder {}

extension Encodable {
    func encoded(using encoder: AnyEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
}

extension KeyedDecodingContainerProtocol {
    func decode<T: Decodable>(forKey key: Key) throws -> T {
        return try decode(T.self, forKey: key)
    }

    func decode<T: Decodable>(
        forKey key: Key,
        default defaultExpression: @autoclosure () -> T
    ) throws -> T {
        return try decodeIfPresent(T.self, forKey: key) ?? defaultExpression()
    }
}

