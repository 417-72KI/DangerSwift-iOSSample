struct InfoPlist: Decodable {
    let bundleVersion: String
    let shortVersionString: String

    enum CodingKeys: String, CodingKey {
        case bundleVersion = "CFBundleVersion"
        case shortVersionString = "CFBundleShortVersionString"
    }
}
