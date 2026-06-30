import Foundation

/// Error thrown when an account number or sorting code cannot be parsed or
/// validated.
public enum KontonummerError: Error, Hashable, Sendable {
    /// The sorting code is shorter than 4 digits, or its 5th-digit mod-10
    /// check failed.
    case invalidSortingCode
    /// The account number has an invalid length or check digit.
    case invalidAccountNumber
    /// No bank is registered for the sorting code.
    case unknownSortingCode(String)
}

extension KontonummerError: CustomStringConvertible, LocalizedError {
    public var description: String {
        switch self {
        case .invalidSortingCode:
            "Invalid sorting code"
        case .invalidAccountNumber:
            "Invalid account number"
        case .unknownSortingCode(let sortingCode):
            "No bank found with sorting code \(sortingCode)"
        }
    }

    public var errorDescription: String? { description }
}
