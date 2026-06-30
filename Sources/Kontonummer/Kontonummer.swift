/// A parsed and validated Swedish bank account number (sorting code +
/// account number).
public struct Kontonummer: Equatable, Hashable, Sendable {

    /// Validation strictness.
    public enum Mode: Sendable, CaseIterable {
        /// Validates sorting code, account-number length and check digit;
        /// throws if any check fails.
        case strict
        /// Strict checks for type 1 accounts (4+7) but lax checks for type 2.
        /// Account numbers that become valid once padded are accepted.
        case semi
        /// Never throws for a failed length/check-digit test; instead reports it
        /// through ``isValid``. Still throws for an unknown/invalid sorting code.
        case lax
    }

    /// The registry entry the sorting code matched.
    public let bank: SortingCodeInfo

    public let sortingCode: String
    public let accountNumber: String
    /// Whether the number is valid. Only meaningful in ``Mode/lax`` mode — the
    /// other modes throw instead of constructing an invalid value.
    public let isValid: Bool

    /// The name of the bank the sorting code belongs to.
    public var bankName: String { bank.bankName }

    // MARK: - Public initialisers

    /// Parses a combined `"sortingCode + accountNumber"` string (e.g.
    /// `"9071, 417 23 83"`). Only the digits are considered. A combined type 1
    /// number must carry all 7 account digits.
    public init(_ sortingCodeAndAccountNumber: String, mode: Mode = .strict) throws {
        let digits = sortingCodeAndAccountNumber.digitsOnly
        let sortingCode = Self.sortingCodeDigits(digits)
        try self.init(
            sortingCode: sortingCode,
            accountNumber: String(digits.dropFirst(sortingCode.count)),
            mode: mode,
            combined: true
        )
    }

    /// Parses a separate sorting code and account number. A short type 1
    /// account number is zero-padded before validation.
    public init(sortingCode: String, accountNumber: String, mode: Mode = .strict) throws {
        try self.init(
            sortingCode: Self.sortingCodeDigits(sortingCode.digitsOnly),
            accountNumber: accountNumber.digitsOnly,
            mode: mode,
            combined: false
        )
    }

    // MARK: - Designated initialiser

    /// `combined` records whether the account number was split out of a
    /// combined string: a combined type 1 number must carry all 7 account
    /// digits, whereas a separately provided one may be short (it gets
    /// zero-padded for the check-digit test).
    private init(sortingCode: String, accountNumber: String, mode: Mode, combined: Bool) throws {
        // Validate the sorting code: at least 4 digits, and a valid mod-10 check
        // digit if a 5th digit is present.
        if sortingCode.count < 4 || (sortingCode.count > 4 && !Self.mod10(sortingCode)) {
            throw KontonummerError.invalidSortingCode
        }

        if accountNumber.count < 2 {
            throw KontonummerError.invalidAccountNumber
        }

        guard let bank = SortingCodeInfo.lookup(sortingCode) else {
            throw KontonummerError.unknownSortingCode(sortingCode)
        }

        let accountMaxLength = bank.type == .type2 ? (bank.accountMaxLength ?? 7) : 7
        let accountMinLength = bank.type == .type2
            ? (bank.accountMinLength ?? 2)
            : (combined ? 7 : 2)
        let lengthValid = accountNumber.count <= accountMaxLength && accountNumber.count >= accountMinLength

        // strict throws for any failed check; semi only for type 1 failures.
        let throwing = mode == .strict || (mode == .semi && bank.type == .type1)

        if !lengthValid, throwing { throw KontonummerError.invalidAccountNumber }

        let checksumValid = Self.validateCheckDigit(
            type: bank.type,
            comment: bank.comment,
            sortingCode: sortingCode,
            accountNumber: accountNumber
        )

        if !checksumValid, throwing { throw KontonummerError.invalidAccountNumber }

        self.bank = bank
        self.sortingCode = sortingCode
        self.accountNumber = accountNumber
        self.isValid = checksumValid && (mode == .strict ? lengthValid : true)
    }

    /// Extracts the sorting code from the front of a digit string. Swedbank
    /// 8xxx-x sorting codes have 5 digits; all others have 4.
    private static func sortingCodeDigits(_ digits: String) -> String {
        String(digits.prefix(digits.hasPrefix("8") ? 5 : 4))
    }

    // MARK: - Formatting

    /// Returns the sorting code and account number as a single formatted string.
    /// Defaults to ``FormatStyle/numeric``.
    public func formatted(_ style: FormatStyle = .numeric) -> String {
        bank.formatted(sortingCode: sortingCode, accountNumber: accountNumber, style: style)
    }

    // MARK: - Static helpers

    /// Returns `true` if the combined string parses in strict mode.
    public static func isValid(_ sortingCodeAndAccountNumber: String) -> Bool {
        (try? Kontonummer(sortingCodeAndAccountNumber)) != nil
    }

    /// Returns `true` if the separate sorting code and account number parse in
    /// strict mode.
    public static func isValid(sortingCode: String, accountNumber: String) -> Bool {
        (try? Kontonummer(sortingCode: sortingCode, accountNumber: accountNumber)) != nil
    }
}

// MARK: - Codable

extension Kontonummer: Codable {
    private enum CodingKeys: String, CodingKey {
        case sortingCode
        case accountNumber
    }

    /// Decodes the sorting code and account number, then re-validates in
    /// ``Mode/lax`` mode so `isValid` and the bank details are recomputed
    /// rather than trusted from the payload. Throws for an unknown sorting
    /// code.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            sortingCode: container.decode(String.self, forKey: .sortingCode),
            accountNumber: container.decode(String.self, forKey: .accountNumber),
            mode: .lax
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sortingCode, forKey: .sortingCode)
        try container.encode(accountNumber, forKey: .accountNumber)
    }
}
