extension Kontonummer {
    /// Output style for ``Kontonummer/formatted(_:)``.
    public enum FormatStyle: Sendable, CaseIterable {
        case numeric
        case pretty
    }
}

/// Applies a formatting mask to a sorting code and account number.
///
/// Mask key: `S` = sorting code digit, `A` = account number digit. Any other
/// character is emitted literally. The sorting code is consumed left-to-right;
/// the account number right-to-left so that zero-padding lands at the start.
///
/// - Parameter pad: when `true`, the account number is zero-padded to fill the
///   mask; when `false`, leading mask separators are dropped for short numbers.
func applyMask(_ sortingCode: String, _ accountNumber: String, mask: String, pad: Bool = false) -> String {
    let maskChars = Array(mask)
    // Index just past the last 'S' (0 when there is no 'S').
    let splitIndex = (maskChars.lastIndex(of: "S").map { $0 + 1 }) ?? 0
    let sortingCodeMask = Array(maskChars[0..<splitIndex])
    let accountNumberMask = Array(maskChars[splitIndex...])

    var sortingCodeResult: [String] = []
    var accountNumberResult: [String] = []
    var sortingCodeChars = sortingCode.map(String.init)
    var accountNumberChars = accountNumber.map(String.init)

    // Sorting code: walk the mask left-to-right, replacing each 'S' (or any
    // position beyond the mask) with the next sorting-code digit.
    let sortingLoopCount = max(sortingCodeMask.count, sortingCodeChars.count)
    var index = 0
    while index < sortingLoopCount {
        if index >= sortingCodeMask.count || sortingCodeMask[index] == "S" {
            sortingCodeResult.append(sortingCodeChars.isEmpty ? "" : sortingCodeChars.removeFirst())
        } else {
            sortingCodeResult.append(String(sortingCodeMask[index]))
        }
        if sortingCodeChars.isEmpty { break }
        index += 1
    }

    // Account number: walk the mask right-to-left so any zero-padding ends up at
    // the start of the number.
    let firstAIndex = accountNumberMask.firstIndex(of: "A") ?? -1
    var accountIndex = accountNumberMask.count - 1
    while accountIndex >= 0 {
        if accountNumberMask[accountIndex] == "A" {
            if let next = accountNumberChars.popLast() {
                accountNumberResult.insert(next, at: 0)
            } else {
                accountNumberResult.insert(pad ? "0" : "", at: 0)
            }
        } else {
            accountNumberResult.insert(String(accountNumberMask[accountIndex]), at: 0)
        }

        // More account digits than mask 'A's: dump the remainder at the start.
        if accountIndex == firstAIndex, !accountNumberChars.isEmpty {
            while let next = accountNumberChars.popLast() {
                accountNumberResult.insert(next, at: 0)
            }
        }

        // No more digits and not padding: prepend the mask's leading separators.
        if accountNumberChars.isEmpty, !pad {
            if firstAIndex > 0 {
                let prefix = accountNumberMask[0..<firstAIndex].map(String.init)
                accountNumberResult.insert(contentsOf: prefix, at: 0)
            }
            break
        }
        accountIndex -= 1
    }

    return sortingCodeResult.joined() + accountNumberResult.joined()
}

extension SortingCodeInfo {
    /// Formats a sorting code and account number according to this bank entry
    /// and the requested style.
    public func formatted(
        sortingCode: String,
        accountNumber: String,
        style: Kontonummer.FormatStyle = .numeric
    ) -> String {
        if style == .pretty {
            switch (type, bankName) {
            case (.type1, "Swedbank"):
                return applyMask(sortingCode, accountNumber, mask: "SSSS-AA-AAAAA", pad: true)
            case (.type1, _):
                return applyMask(sortingCode, accountNumber, mask: "SSSS AA AAA AA", pad: true)
            case (_, "Swedbank"):
                return applyMask(sortingCode, accountNumber, mask: "SSSS-S, AAA AAA AAA-A")
            case (_, "Handelsbanken"):
                return applyMask(sortingCode, accountNumber, mask: "SSSS, AAA AAA AAA")
            case (_, "Nordea Plusgirot"):
                return applyMask(sortingCode, accountNumber, mask: "SSSS, AAA AA AA-A")
            case (_, "Nordea"):
                return applyMask(sortingCode, accountNumber, mask: "SSSS, AAAAAA-AAAA")
            default:
                return applyMask(sortingCode, accountNumber, mask: "SSSS-S, AA AAAA AAAA")
            }
        } else {
            let accountLength = accountMinLength ?? 7
            let mask = "SSSSS" + String(repeating: "A", count: accountLength)
            return applyMask(sortingCode, accountNumber, mask: mask, pad: true)
        }
    }
}
