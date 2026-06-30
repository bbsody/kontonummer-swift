extension Kontonummer {
    /// Luhn (mod-10) check.
    ///
    /// Returns `true` when the weighted digit sum is non-zero and divisible by 10.
    static func mod10(_ number: String) -> Bool {
        // Pre-doubled lookup for the "every other digit" positions.
        let doubled = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]
        let digits = number.compactMap(\.wholeNumberValue)
        var sum = 0
        // The rightmost digit is added as-is, the next is doubled (via the
        // table), and so on.
        for (index, digit) in digits.reversed().enumerated() {
            sum += index.isMultiple(of: 2) ? digit : doubled[digit]
        }
        return sum != 0 && sum % 10 == 0
    }

    /// Weighted mod-11 check.
    ///
    /// Uses the trailing `n` weights of `[1,10,9,8,7,6,5,4,3,2,1]` where `n` is
    /// the number length, aligning the leftmost digit with the heaviest weight.
    static func mod11(_ number: String) -> Bool {
        let weights = [1, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        let digits = number.compactMap(\.wholeNumberValue)
        let sum = zip(weights.suffix(digits.count), digits).map(*).reduce(0, +)
        return sum != 0 && sum % 11 == 0
    }

    /// Validates the account-number check digit for a given bank type/comment.
    static func validateCheckDigit(
        type: SortingCodeInfo.AccountType,
        comment: Int,
        sortingCode: String,
        accountNumber: String
    ) -> Bool {
        switch (type, comment) {
        // 1:1 => mod11 on last 3 of clearing + whole account number
        case (.type1, 1):
            return mod11(String(sortingCode.dropFirst()) + accountNumber.leftPadded(toLength: 7))
        // 1:2 => mod11 on whole clearing + whole account number
        case (.type1, 2):
            return mod11(sortingCode + accountNumber.leftPadded(toLength: 7))
        // 2:2 => mod11 on whole account number (SHB) 9 digits
        case (.type2, 2):
            return mod11(accountNumber.leftPadded(toLength: 9))
        // 2:1 & 2:3 => mod10 on the last ten digits. The account number can
        // exceed 10 digits in the lenient Swedbank case (a 5-digit clearing
        // number sent as 4+1); the stray leading digit is not part of the sum.
        default:
            return mod10(String(accountNumber.leftPadded(toLength: 10).suffix(10)))
        }
    }
}
