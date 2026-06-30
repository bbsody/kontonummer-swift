extension String {
    /// Keeps only the ASCII digits `0-9`, discarding everything else.
    var digitsOnly: String {
        filter { $0.isASCII && $0.isNumber }
    }

    /// Left-pads the string with `0` up to `length` characters. Never truncates
    /// a string that is already longer than `length`.
    func leftPadded(toLength length: Int) -> String {
        guard count < length else { return self }
        return String(repeating: "0", count: length - count) + self
    }
}
