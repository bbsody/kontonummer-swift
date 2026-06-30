# kontonummer-swift

Parse and validate Swedish bank account numbers (sorting code /
*clearingnummer* + account number).

It implements the 2024-02-22 version of the [*Bank Account Numbers in Swedish Banks*](https://www.bankgirot.se/globalassets/dokument/anvandarmanualer/bankernaskontonummeruppbyggnad_anvandarmanual_sv.pdf)
specification from Bankgirot.

> [!IMPORTANT]
> Some Swedish account numbers have no check digit and are indistinguishable
> from validatable ones. Use this on form input to *warn*, not to hard-block
> submission.

## Requirements

- Swift 6.0+
- iOS 13+ / macOS 10.15+ / tvOS 13+ / watchOS 6+

## Install

Add the package as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/bbsody/kontonummer-swift.git", from: "1.0.0"),
```

…and add the `Kontonummer` product to your target:

```swift
.target(name: "YourTarget", dependencies: ["Kontonummer"]),
```

In Xcode, use **File ▸ Add Package Dependencies…** and paste the repository URL.

## Usage

```swift
import Kontonummer

// Combined string — non-digit characters are ignored
let konto = try Kontonummer("8424-4,983 189 224-6")
konto.bankName       // "Swedbank"
konto.sortingCode    // "84244"  (Swedbank 8xxx codes are 5 digits)
konto.accountNumber  // "9831892246"
konto.bank.type      // .type2  (the matched registry entry)
konto.isValid        // true

// Separate sorting code and account number.
let nordea = try Kontonummer(sortingCode: "3300", accountNumber: "0006205124")

// Formatting
konto.formatted()         // "842449831892246"        (.numeric, default)
konto.formatted(.pretty)  // "8424-4, 983 189 224-6"

// Non-throwing check.
Kontonummer.isValid("97891111113")   // true
```

A combined string must contain the full account number — for a type 1 account
all 7 digits. A separately provided account number may be shorter; it is
zero-padded before the check-digit test.

### Modes

`Kontonummer.Mode` controls strictness:

- `.strict` (default) — validates sorting code, account-number length and check
  digit; throws on any failure.
- `.semi` — strict checks for type 1 accounts, lax for type 2; padding-valid
  numbers are accepted.
- `.lax` — never throws on a bad length/check digit (still throws on an unknown
  sorting code); reports the result through the `isValid` property.

```swift
let konto = try Kontonummer("6789123456788", mode: .lax)
konto.isValid   // false — bad check digit, but no throw
```

## API

| Member | Description |
| --- | --- |
| `Kontonummer(_:mode:)` | Parse a combined string. |
| `Kontonummer(sortingCode:accountNumber:mode:)` | Parse separate parts. |
| `Kontonummer.isValid(...)` | Non-throwing boolean check. |
| `formatted(_:)` | `.numeric` or `.pretty` string. |
| `bank` / `bankName` | The matched `SortingCodeInfo` registry entry / its name. |
| `SortingCodeInfo.lookup(_:)` | Bank lookup for a sorting code, `nil` if unknown. |
| `SortingCodeInfo.all` | The full bank registry. |
| `SortingCodeInfo.formatted(sortingCode:accountNumber:style:)` | Format arbitrary parts. |
| `KontonummerError` | `.invalidSortingCode`, `.invalidAccountNumber`, `.unknownSortingCode`. |

`Kontonummer` is `Equatable`, `Hashable`, `Sendable` and `Codable`. Coding uses
only the `sortingCode` and `accountNumber` fields; decoding re-validates them
(in `.lax` mode), so a decoded value always carries a recomputed `bankName` and
`isValid` and decoding an unknown sorting code throws.

## Develop

```sh
swift build        # build the library
swift test         # run the test suite
```
