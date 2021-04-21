import Foundation

// MARK: -
private extension Data {
    var hexString: String { map(\.hexString).joined() }

    var intValue: Int { Int(hexString, radix: 16)! }
}

// MARK: -
private extension Data.Element {
    var hexString: String { String(format: "%02x", self) }
}

// MARK: -
private enum PNGColorType: Int {
    case trueColor = 2
    case trueColorWithAlpha = 6
    case grayScale = 0
    case grayScaleWithAlpha = 4
    case indexColor = 3
}

// MARK: -
private enum PNGError: Error, CustomStringConvertible {
    case unexpectedSize(String, expected: CGSize, actual: CGSize)
    case containsAlphaChannel(String)
    case invalidFileName(String)
    case invalidData(URL)

    var description: String {
        switch self {
        case let .unexpectedSize(fileName, expected, actual):
            return """
                Unexpected size of "\(fileName)"
                expected: \(expected)
                actual: \(actual)
                """
        case let .containsAlphaChannel(fileName):
            return "\"\(fileName)\" contains alpha channel!"
        case let .invalidFileName(fileName):
            return "Invalid file name: \(fileName)"
        case let .invalidData(url):
            return "Invalid data: \"\(url)\" is not valid PNG file!"
        }
    }
}

// MARK: -
func verifyPNG(contentsOf url: URL) -> Result<Void, Error> {
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        return .failure(error)
    }
    let fileName = url.lastPathComponent
    print(fileName)
    func detectSizeFromFileName(_ fileName: String) -> CGSize? {
        let regex = try! NSRegularExpression(pattern: #"^.*_(W(?<width1>[0-9]+)|H(?<height2>[0-9]+))(x|×)(W(?<width2>[0-9]+)|H(?<height1>[0-9]+)).*\.png$"#)
        guard let matches = regex.firstMatch(in: fileName, range: .init(location: 0, length: fileName.count)) else { return nil }
        switch (
            Range(matches.range(withName: "width1"), in: fileName),
            Range(matches.range(withName: "height1"), in: fileName),
            Range(matches.range(withName: "width2"), in: fileName),
            Range(matches.range(withName: "height2"), in: fileName)
        ) {
        case let (width?, height?, nil, nil):
            let width = Int(fileName[width])!
            let height = Int(fileName[height])!
            return CGSize(width: width, height: height)
        case let (nil, nil, width?, height?):
            let width = Int(fileName[width])!
            let height = Int(fileName[height])!
            return CGSize(width: width, height: height)
        default:
            return nil
        }
    }

    guard let expectedSize = detectSizeFromFileName(fileName) else { return .failure(PNGError.invalidFileName(fileName)) }

    let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    let ihdrChunkHeader: [UInt8] = [0, 0, 0, 13, 73, 72, 68, 82]

    guard Array(data.prefix(16)) == signature + ihdrChunkHeader else { // data is PNG
        return .failure(PNGError.invalidData(url))
    }
    let ihdrChunk = data.advanced(by: 16).prefix(13)
    let width = ihdrChunk.prefix(4).intValue
    let height = ihdrChunk.dropFirst(4).prefix(4).intValue
    guard width == Int(expectedSize.width), height == Int(expectedSize.height) else {
        return .failure(PNGError.unexpectedSize(fileName, expected: expectedSize, actual: CGSize(width: width, height: height)))
    }

    _ = ihdrChunk.dropFirst(8).prefix(1).intValue // depth
    switch PNGColorType(rawValue: ihdrChunk.dropFirst(9).prefix(1).intValue) {
    case .indexColor:
        _ = data.advanced(by: 29) // PLTE
        // TODO: detect alpha channnel
    case .trueColorWithAlpha, .grayScaleWithAlpha:
        return .failure(PNGError.containsAlphaChannel(fileName))
    default:
        break
    }
    return .success(())
}
