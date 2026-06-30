import Testing
@testable import Kontonummer

@Suite("applyMask")
struct ApplyMaskSuite {
    // sortingCode, accountNumber, mask, pad, expected
    static let cases: [(String, String, String, Bool, String)] = [
        ("1111", "1122233", "SSSS AA AAA AA", true, "1111 11 222 33"),
        ("1111", "122233", "SSSS AA AAA AA", true, "1111 01 222 33"),
        ("1111", "122233", "SSSS AA AAA AA", false, "1111 1 222 33"),
        ("1111", "22233", "SSSS AA AAA AA", true, "1111 00 222 33"),
        ("1111", "22233", "SSSS AA AAA AA", false, "1111 222 33"),

        ("1111", "1122233", "SSSS-AA-AAAAA", false, "1111-11-22233"),
        ("1111", "1122233", "SSSS-AA-AAAAA", true, "1111-11-22233"),
        ("1111", "122233", "SSSS-AA-AAAAA", false, "1111-1-22233"),
        ("1111", "122233", "SSSS-AA-AAAAA", true, "1111-01-22233"),
        ("1111", "22233", "SSSS-AA-AAAAA", false, "1111-22233"),
        ("1111", "22233", "SSSS-AA-AAAAA", true, "1111-00-22233"),

        ("11111", "1112223334", "SSSS-S, AAA AAA AAA-A", false, "1111-1, 111 222 333-4"),
        ("11111", "2223334", "SSSS-S, AAA AAA AAA-A", false, "1111-1, 222 333-4"),
        ("11111", "3334", "SSSS-S, AAA AAA AAA-A", false, "1111-1, 333-4"),
        ("11111", "4", "SSSS-S, AAA AAA AAA-A", false, "1111-1, 4"),

        ("1111", "111222333", "SSSS, AAA AAA AAA", false, "1111, 111 222 333"),
        ("1111", "11222333", "SSSS, AAA AAA AAA", false, "1111, 11 222 333"),

        ("1111", "1122334444", "SSSS, AAAAAA-AAAA", false, "1111, 112233-4444"),

        ("1111", "123456", "SSSS, A-A", false, "1111, 12345-6"),
    ]

    @Test("formats correctly", arguments: cases)
    func formats(_ test: (String, String, String, Bool, String)) {
        let (sortingCode, accountNumber, mask, pad, expected) = test
        #expect(applyMask(sortingCode, accountNumber, mask: mask, pad: pad) == expected)
    }
}

@Suite("formatted")
struct FormattedSuite {
    private func avanza() -> SortingCodeInfo {
        .init(bankName: "Avanza Bank", type: .type1, comment: 2, ranges: [9550...9569])
    }

    @Test("Should format numerically")
    func numeric() {
        #expect(avanza().formatted(sortingCode: "1111", accountNumber: "1234567") == "11111234567")
    }

    @Test("Should format numerically and pad")
    func numericPad() {
        #expect(avanza().formatted(sortingCode: "1111", accountNumber: "34567") == "11110034567")
    }

    @Test("Should format 5-digit clearing number numerically")
    func numericFiveDigit() {
        #expect(avanza().formatted(sortingCode: "11111", accountNumber: "1234567") == "111111234567")
    }

    @Test("Should pretty format Swedbank type 1")
    func prettySwedbankType1() {
        let info = SortingCodeInfo(bankName: "Swedbank", type: .type1, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "1234567", style: .pretty) == "1111-12-34567")
    }

    @Test("Should pretty format type 1")
    func prettyType1() {
        let info = SortingCodeInfo(bankName: "Danske Bank", type: .type1, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "1234567", style: .pretty) == "1111 12 345 67")
    }

    @Test("Should format Swedbank type 2 with 5 digit")
    func prettySwedbankType2() {
        let info = SortingCodeInfo(bankName: "Swedbank", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "11111", accountNumber: "1234567890", style: .pretty) == "1111-1, 123 456 789-0")
    }

    @Test("Should format Handelsbanken type 2")
    func prettyHandelsbanken() {
        let info = SortingCodeInfo(bankName: "Handelsbanken", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "123456789", style: .pretty) == "1111, 123 456 789")
    }

    @Test("Should format Handelsbanken type 2 with short number")
    func prettyHandelsbankenShort() {
        let info = SortingCodeInfo(bankName: "Handelsbanken", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "23456789", style: .pretty) == "1111, 23 456 789")
    }

    @Test("Should format short Nordea PlusGirot")
    func prettyPlusgirotShort() {
        let info = SortingCodeInfo(bankName: "Nordea Plusgirot", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "12", style: .pretty) == "1111, 1-2")
    }

    @Test("Should format medium Nordea PlusGirot")
    func prettyPlusgirotMedium() {
        let info = SortingCodeInfo(bankName: "Nordea Plusgirot", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "1234", style: .pretty) == "1111, 1 23-4")
    }

    @Test("Should format long Nordea PlusGirot")
    func prettyPlusgirotLong() {
        let info = SortingCodeInfo(bankName: "Nordea Plusgirot", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "12345678", style: .pretty) == "1111, 123 45 67-8")
    }

    @Test("Should format other type 2")
    func prettyOtherType2() {
        let info = SortingCodeInfo(bankName: "Danske Bank", type: .type2, comment: 2, ranges: [9550...9569])
        #expect(info.formatted(sortingCode: "1111", accountNumber: "1234567890", style: .pretty) == "1111, 12 3456 7890")
    }
}
