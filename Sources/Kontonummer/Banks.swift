/// Information about a bank associated with a range of sorting codes
/// (sv. *clearingnummer*).
public struct SortingCodeInfo: Equatable, Hashable, Sendable {
    /// The two account-number layouts in the Bankgirot specification.
    public enum AccountType: Int, Hashable, Sendable {
        /// Fixed length: 4-digit sorting code + 7-digit account number.
        case type1 = 1
        /// Variable length; rules differ per bank (the messy ones).
        case type2 = 2
    }

    public let bankName: String
    public let type: AccountType
    /// Validation variant within the type — the *Kommentar* column of the
    /// Bankgirot specification (`1`, `2` or `3`). Selects the check-digit
    /// algorithm.
    public let comment: Int
    /// Inclusive sorting-code ranges that belong to this bank entry.
    public let ranges: [ClosedRange<Int>]
    /// Minimum account-number length (type 2 only).
    public let accountMinLength: Int?
    /// Maximum account-number length (type 2 only).
    public let accountMaxLength: Int?

    public init(
        bankName: String,
        type: AccountType,
        comment: Int,
        ranges: [ClosedRange<Int>],
        accountMinLength: Int? = nil,
        accountMaxLength: Int? = nil
    ) {
        self.bankName = bankName
        self.type = type
        self.comment = comment
        self.ranges = ranges
        self.accountMinLength = accountMinLength
        self.accountMaxLength = accountMaxLength
    }

    /// Looks up the bank entry for a sorting code by matching the first four
    /// digits against the registry ranges. Returns `nil` if no bank matches.
    public static func lookup(_ sortingCode: String) -> SortingCodeInfo? {
        guard let number = Int(sortingCode.digitsOnly.prefix(4)) else { return nil }
        return all.first { bank in
            bank.ranges.contains { $0.contains(number) }
        }
    }
}

extension SortingCodeInfo {
    /// The full bank registry.
    ///
    /// Implements the 2024-02-22 version of the *Bankernas kontonummeruppbyggnad*
    /// specification from Bankgirot.
    public static let all: [SortingCodeInfo] = [
        // MARK: Type 1 accounts — always 11 digits long, sorting code included.
        // SSSSAAAAAAC
        .init(bankName: "Aion Bank", type: .type1, comment: 1, ranges: [9580...9589]),
        .init(bankName: "Avanza Bank", type: .type1, comment: 2, ranges: [9550...9569]),
        .init(bankName: "BlueStep Finans", type: .type1, comment: 1, ranges: [9680...9689]),
        .init(bankName: "BNP Paribas", type: .type1, comment: 2, ranges: [9470...9479]),
        .init(bankName: "Citibank", type: .type1, comment: 2, ranges: [9040...9049]),
        .init(bankName: "Danske Bank", type: .type1, comment: 1, ranges: [1200...1399, 2400...2499]),
        .init(bankName: "DNB Bank", type: .type1, comment: 2, ranges: [9190...9199, 9260...9269]),
        .init(bankName: "Ekobanken", type: .type1, comment: 2, ranges: [9700...9709]),
        .init(bankName: "Erik Penser", type: .type1, comment: 2, ranges: [9590...9599]),
        .init(bankName: "ICA Banken", type: .type1, comment: 1, ranges: [9270...9279]),
        .init(bankName: "IKANO Bank", type: .type1, comment: 1, ranges: [9170...9179]),
        .init(bankName: "JAK Medlemsbank", type: .type1, comment: 2, ranges: [9670...9679]),
        .init(bankName: "Klarna Bank", type: .type1, comment: 2, ranges: [9780...9789]),
        .init(bankName: "Landshypotek", type: .type1, comment: 2, ranges: [9390...9399]),
        .init(bankName: "Lunar Bank", type: .type1, comment: 2, ranges: [9710...9719]),
        .init(bankName: "Lån & Spar Bank Sverige", type: .type1, comment: 1, ranges: [9630...9639]),
        .init(bankName: "Länsförsäkringar Bank", type: .type1, comment: 1, ranges: [3400...3409, 9060...9069]),
        .init(bankName: "Länsförsäkringar Bank", type: .type1, comment: 2, ranges: [9020...9029]),
        .init(bankName: "Marginalen Bank", type: .type1, comment: 1, ranges: [9230...9239]),
        .init(bankName: "Multitude Bank", type: .type1, comment: 1, ranges: [9070...9079]),
        .init(bankName: "NOBA Bank Group AB", type: .type1, comment: 2, ranges: [9640...9649]),
        .init(bankName: "Nordea", type: .type1, comment: 1, ranges: [
            1100...1199, 1400...2099, 3000...3299,
            3301...3399, 3410...3781, 3783...3999,
        ]),
        .init(bankName: "Nordea", type: .type1, comment: 2, ranges: [4000...4999]),
        .init(bankName: "Nordnet Bank", type: .type1, comment: 2, ranges: [9100...9109]),
        .init(bankName: "Northmill Bank", type: .type1, comment: 2, ranges: [9750...9759]),
        .init(bankName: "Resurs Bank", type: .type1, comment: 1, ranges: [9280...9289]),
        .init(bankName: "Riksgälden", type: .type1, comment: 2, ranges: [9880...9889]),
        .init(bankName: "Santander Consumer Bank", type: .type1, comment: 1, ranges: [9460...9469]),
        .init(bankName: "SBAB", type: .type1, comment: 1, ranges: [9250...9259]),
        .init(bankName: "SEB", type: .type1, comment: 1, ranges: [5000...5999, 9120...9124, 9130...9149]),
        .init(bankName: "Skandiabanken", type: .type1, comment: 2, ranges: [9150...9169]),
        .init(bankName: "Svea Bank", type: .type1, comment: 2, ranges: [9660...9669]),
        .init(bankName: "Swedbank", type: .type1, comment: 1, ranges: [7000...7999]),
        .init(bankName: "Ålandsbanken", type: .type1, comment: 2, ranges: [2300...2399]),

        // MARK: Type 2 accounts — the messy ones.
        .init(bankName: "Danske Bank", type: .type2, comment: 1, ranges: [9180...9189],
              accountMinLength: 10, accountMaxLength: 10),
        .init(bankName: "Handelsbanken", type: .type2, comment: 2, ranges: [6000...6999],
              accountMinLength: 8, accountMaxLength: 9),
        .init(bankName: "Nordea", type: .type2, comment: 1, ranges: [3300...3300, 3782...3782],
              accountMinLength: 10, accountMaxLength: 10),
        .init(bankName: "Nordea Plusgirot", type: .type2, comment: 3, ranges: [9500...9549, 9960...9969],
              accountMinLength: 2, accountMaxLength: 8),
        .init(bankName: "Riksgälden", type: .type2, comment: 1, ranges: [9890...9899],
              accountMinLength: 10, accountMaxLength: 10),
        // Swedbank: extra 5-digit case to catch their 5-digit sorting codes.
        // source: swedbank.se/.../clearingnummer.html
        .init(bankName: "Swedbank", type: .type2, comment: 3, ranges: [8000...8999],
              accountMinLength: 10, // Allowing 11 below in case the clearing number
              accountMaxLength: 11), // is sent as the first four instead of the first five.
        .init(bankName: "Swedbank", type: .type2, comment: 1, ranges: [9300...9349],
              accountMinLength: 10, accountMaxLength: 10),
    ]
}
