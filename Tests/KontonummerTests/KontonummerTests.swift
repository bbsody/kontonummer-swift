import Foundation
import Testing
@testable import Kontonummer

@Suite("Kontonummer")
struct KontonummerSuite {
    @Test("Should validate a Multitude Bank account")
    func multitudeBank() throws {
        let forex = try Kontonummer("9071, 417 23 83")
        #expect(forex.bankName == "Multitude Bank")
        #expect(forex.sortingCode == "9071")
        #expect(forex.accountNumber == "4172383")
    }

    @Test("Should validate a Handelsbanken account")
    func handelsbanken() throws {
        let handelsbanken = try Kontonummer("6789123456789")
        #expect(handelsbanken.bankName == "Handelsbanken")
        #expect(handelsbanken.sortingCode == "6789")
        #expect(handelsbanken.accountNumber == "123456789")
    }

    @Test("Should verify a Swedbank account number with a 5 digit sorting code")
    func swedbankFiveDigit() throws {
        let swedbank5 = try Kontonummer("8424-4,983 189 224-6")
        #expect(swedbank5.bankName == "Swedbank")
        #expect(swedbank5.sortingCode == "84244")
        #expect(swedbank5.accountNumber == "9831892246")
    }

    @Test("Should verify an account number from Sparbanken Tanum")
    func sparbankenTanum() throws {
        let tanum = try Kontonummer("8351-9,392 242 224-5")
        #expect(tanum.bankName == "Swedbank")
        #expect(tanum.sortingCode == "83519")
        #expect(tanum.accountNumber == "3922422245")
    }

    @Test("Should verify an account number from Sparbank i Hudiksvall")
    func hudiksvall() throws {
        let hudik = try Kontonummer("8129-9,043 386 711-6")
        #expect(hudik.bankName == "Swedbank")
        #expect(hudik.sortingCode == "81299")
        #expect(hudik.accountNumber == "0433867116")
    }

    @Test("Should verify a Nordea personkonto")
    func nordeaPersonkonto() throws {
        let nordea = try Kontonummer("3300 000620-5124")
        #expect(nordea.bankName == "Nordea")
        #expect(nordea.sortingCode == "3300")
        #expect(nordea.accountNumber == "0006205124")
    }

    @Test("Should verify a Klarna account number")
    func klarna() throws {
        let klarna = try Kontonummer("97891111113")
        #expect(klarna.bankName == "Klarna Bank")
        #expect(klarna.sortingCode == "9789")
        #expect(klarna.accountNumber == "1111113")
    }

    @Test("Should throw for an invalid account number")
    func throwsInvalidAccount() {
        #expect(throws: KontonummerError.invalidAccountNumber) {
            try Kontonummer("123456789")
        }
    }

    @Test("Should throw if the check digit is invalid")
    func throwsInvalidCheckDigit() {
        #expect(throws: KontonummerError.invalidAccountNumber) {
            try Kontonummer("6789123456788")
        }
    }

    @Test("Should throw if a type 1 account is provided as a single string of incorrect length")
    func throwsType1WrongLength() {
        // The combined-string minimum length must not depend on whether a mode
        // argument was supplied.
        #expect(throws: KontonummerError.invalidAccountNumber) {
            try Kontonummer("512200")
        }
        #expect(throws: KontonummerError.invalidAccountNumber) {
            try Kontonummer("512200", mode: .strict)
        }
    }

    @Test("Should treat account numbers needing padding as invalid in strict mode")
    func throwsPaddingStrict() {
        #expect(throws: KontonummerError.invalidAccountNumber) {
            try Kontonummer(sortingCode: "5122", accountNumber: "0", mode: .strict)
        }
    }

    @Test("Should treat account numbers needing padding as valid in semi mode")
    func paddingSemiValid() throws {
        let konto = try Kontonummer(sortingCode: "5122", accountNumber: "00", mode: .semi)
        #expect(konto.isValid == true)
    }

    @Test("Should throw if the check digit on a 5 digit sorting code is invalid")
    func throwsInvalidSortingCheck() {
        #expect(throws: KontonummerError.invalidSortingCode) {
            try Kontonummer("8424-1,983 189 224-6")
        }
    }

    @Test("Should report a bad check digit through `isValid` in lax mode")
    func laxInvalidCheckDigit() throws {
        let konto = try Kontonummer("6789123456788", mode: .lax)
        #expect(konto.isValid == false)
        #expect(konto.bankName == "Handelsbanken")
    }

    @Test("Should still throw for an unknown sorting code in lax mode")
    func laxUnknownSortingCode() {
        #expect(throws: KontonummerError.unknownSortingCode("1000")) {
            try Kontonummer("1000, 123 45 67", mode: .lax)
        }
    }

    @Test("Should validate via the static isValid helpers")
    func staticValid() {
        #expect(Kontonummer.isValid("97891111113"))
        #expect(!Kontonummer.isValid("97891111112"))
        #expect(Kontonummer.isValid(sortingCode: "3300", accountNumber: "0006205124"))
        #expect(!Kontonummer.isValid(sortingCode: "3300", accountNumber: "0006205125"))
    }

    @Test("Should give 3400-3409 to Länsförsäkringar and 3410-3499 to Nordea")
    func lansforsakringarNordeaBoundary() {
        #expect(SortingCodeInfo.lookup("3400")?.bankName == "Länsförsäkringar Bank")
        #expect(SortingCodeInfo.lookup("3409")?.bankName == "Länsförsäkringar Bank")
        #expect(SortingCodeInfo.lookup("3410")?.bankName == "Nordea")
        #expect(SortingCodeInfo.lookup("3499")?.bankName == "Nordea")
    }

    @Test("Should checksum only the last ten digits when a Swedbank account carries the 5th clearing digit")
    func swedbankElevenDigitAccount() throws {
        // Same account as "8424-4, 983 189 224-6", but with the clearing number
        // sent as its first four digits and the 5th riding in the account field.
        let konto = try Kontonummer(sortingCode: "8424", accountNumber: "49831892246")
        #expect(konto.bankName == "Swedbank")
        #expect(konto.isValid)
    }

    @Test("Should format a parsed account")
    func formatsInstance() throws {
        let konto = try Kontonummer("8424-4,983 189 224-6")
        #expect(konto.formatted() == "842449831892246")
        #expect(konto.formatted(.pretty) == "8424-4, 983 189 224-6")
    }
}

@Suite("Codable")
struct CodableSuite {
    @Test("Should round-trip through Codable")
    func roundTrip() throws {
        let original = try Kontonummer("9071, 417 23 83")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Kontonummer.self, from: data)
        #expect(decoded == original)
        #expect(decoded.isValid == true)
    }

    @Test("Should recompute `isValid` when decoding")
    func recomputesValid() throws {
        let json = Data(#"{"sortingCode":"6789","accountNumber":"123456788"}"#.utf8)
        let decoded = try JSONDecoder().decode(Kontonummer.self, from: json)
        #expect(decoded.isValid == false)
        #expect(decoded.bankName == "Handelsbanken")
    }

    @Test("Should refuse to decode an unknown sorting code")
    func rejectsUnknownSortingCode() {
        let json = Data(#"{"sortingCode":"1000","accountNumber":"1234567"}"#.utf8)
        #expect(throws: KontonummerError.self) {
            try JSONDecoder().decode(Kontonummer.self, from: json)
        }
    }
}

@Suite("KontonummerError")
struct KontonummerErrorSuite {
    @Test("Should describe each case")
    func describesCases() {
        #expect("\(KontonummerError.invalidSortingCode)" == "Invalid sorting code")
        #expect("\(KontonummerError.invalidAccountNumber)" == "Invalid account number")
        #expect("\(KontonummerError.unknownSortingCode("1234"))" == "No bank found with sorting code 1234")
        #expect(KontonummerError.invalidAccountNumber.errorDescription == "Invalid account number")
    }
}
