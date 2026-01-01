// SyntaxHighlighter.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import Foundation

/// A token type for syntax highlighting.
public enum TokenType: Sendable {
    /// A language keyword (e.g., `let`, `func`, `class`, `if`, `return`).
    case keyword
    /// A string literal.
    case string
    /// A comment.
    case comment
    /// A numeric literal.
    case number
    /// A type name.
    case type
    /// A function or method name.
    case function
    /// Plain text (default).
    case plain
}

/// A token representing a highlighted segment of code.
public struct Token: Sendable {
    /// The text content of this token.
    public let text: String
    /// The type of this token for coloring.
    public let type: TokenType

    public init(text: String, type: TokenType) {
        self.text = text
        self.type = type
    }
}

/// A simple syntax highlighter that tokenizes code for common languages.
///
/// Supports Swift, Python, JavaScript, TypeScript, Java, C, C++, Go, Rust, Ruby,
/// and other common languages. Falls back to plain text for unknown languages.
public struct SyntaxHighlighter: Sendable {

    public init() {}

    /// Tokenizes the given code based on the specified language.
    ///
    /// - Parameters:
    ///   - code: The source code to tokenize.
    ///   - language: The programming language (e.g., "swift", "python", "javascript").
    /// - Returns: An array of tokens representing the highlighted code.
    public func tokenize(_ code: String, language: String?) -> [Token] {
        guard let language = language?.lowercased() else {
            return [Token(text: code, type: .plain)]
        }

        let keywords = Self.keywords(for: language)
        let commentPatterns = Self.commentPatterns(for: language)

        var tokens: [Token] = []
        var remaining = code[...]
        var currentPlain = ""

        while !remaining.isEmpty {
            // Try to match a comment
            if let (commentToken, rest) = tryMatchComment(remaining, patterns: commentPatterns) {
                if !currentPlain.isEmpty {
                    tokens.append(Token(text: currentPlain, type: .plain))
                    currentPlain = ""
                }
                tokens.append(commentToken)
                remaining = rest
                continue
            }

            // Try to match a string
            if let (stringToken, rest) = tryMatchString(remaining) {
                if !currentPlain.isEmpty {
                    tokens.append(Token(text: currentPlain, type: .plain))
                    currentPlain = ""
                }
                tokens.append(stringToken)
                remaining = rest
                continue
            }

            // Try to match a number
            if let (numberToken, rest) = tryMatchNumber(remaining) {
                if !currentPlain.isEmpty {
                    tokens.append(Token(text: currentPlain, type: .plain))
                    currentPlain = ""
                }
                tokens.append(numberToken)
                remaining = rest
                continue
            }

            // Try to match an identifier (keyword, type, or function)
            if let (identToken, rest) = tryMatchIdentifier(remaining, keywords: keywords) {
                if !currentPlain.isEmpty {
                    tokens.append(Token(text: currentPlain, type: .plain))
                    currentPlain = ""
                }
                tokens.append(identToken)
                remaining = rest
                continue
            }

            // No match, consume one character as plain text
            currentPlain.append(remaining.removeFirst())
        }

        if !currentPlain.isEmpty {
            tokens.append(Token(text: currentPlain, type: .plain))
        }

        return tokens
    }

    // MARK: - Comment Matching

    private func tryMatchComment(_ input: Substring, patterns: (line: String?, block: (start: String, end: String)?)) -> (Token, Substring)? {
        // Try line comment
        if let linePrefix = patterns.line, input.hasPrefix(linePrefix) {
            let startIndex = input.startIndex
            var endIndex = input.endIndex
            if let newlineIndex = input.firstIndex(of: "\n") {
                endIndex = input.index(after: newlineIndex)
            }
            let comment = String(input[startIndex..<endIndex])
            return (Token(text: comment, type: .comment), input[endIndex...])
        }

        // Try block comment
        if let block = patterns.block, input.hasPrefix(block.start) {
            let afterStart = input.index(input.startIndex, offsetBy: block.start.count)
            if let endRange = input[afterStart...].range(of: block.end) {
                let endIndex = endRange.upperBound
                let comment = String(input[input.startIndex..<endIndex])
                return (Token(text: comment, type: .comment), input[endIndex...])
            } else {
                // Unclosed block comment - treat rest as comment
                return (Token(text: String(input), type: .comment), input[input.endIndex...])
            }
        }

        return nil
    }

    // MARK: - String Matching

    private func tryMatchString(_ input: Substring) -> (Token, Substring)? {
        let quoteChars: [Character] = ["\"", "'", "`"]
        guard let firstChar = input.first, quoteChars.contains(firstChar) else {
            return nil
        }

        // Handle triple-quoted strings
        if input.hasPrefix("\"\"\"") || input.hasPrefix("'''") {
            let quote = String(input.prefix(3))
            let afterQuote = input.index(input.startIndex, offsetBy: 3)
            if let endRange = input[afterQuote...].range(of: quote) {
                let endIndex = endRange.upperBound
                let string = String(input[input.startIndex..<endIndex])
                return (Token(text: string, type: .string), input[endIndex...])
            }
        }

        // Single-char quote
        let quote = firstChar
        var index = input.index(after: input.startIndex)
        var escaped = false

        while index < input.endIndex {
            let char = input[index]
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == quote {
                let endIndex = input.index(after: index)
                let string = String(input[input.startIndex..<endIndex])
                return (Token(text: string, type: .string), input[endIndex...])
            } else if char == "\n" && quote != "`" {
                // Unterminated string at newline
                break
            }
            index = input.index(after: index)
        }

        return nil
    }

    // MARK: - Number Matching

    private func tryMatchNumber(_ input: Substring) -> (Token, Substring)? {
        guard let firstChar = input.first else { return nil }

        // Check if it starts with a digit or a dot followed by a digit
        let startsWithDigit = firstChar.isNumber
        let startsWithDot = firstChar == "." && input.dropFirst().first?.isNumber == true

        guard startsWithDigit || startsWithDot else { return nil }

        // Don't match if preceded by a letter (part of identifier)
        // This is handled by identifier matching first

        var index = input.startIndex
        var hasDecimal = startsWithDot
        var hasExponent = false

        // Handle hex/octal/binary prefixes
        if firstChar == "0" && input.count > 1 {
            let second = input[input.index(after: input.startIndex)]
            if second == "x" || second == "X" || second == "o" || second == "O" || second == "b" || second == "B" {
                index = input.index(input.startIndex, offsetBy: 2)
                while index < input.endIndex {
                    let char = input[index]
                    if char.isHexDigit || char == "_" {
                        index = input.index(after: index)
                    } else {
                        break
                    }
                }
                let number = String(input[input.startIndex..<index])
                return (Token(text: number, type: .number), input[index...])
            }
        }

        while index < input.endIndex {
            let char = input[index]
            if char.isNumber || char == "_" {
                index = input.index(after: index)
            } else if char == "." && !hasDecimal && !hasExponent {
                // Check if next char is a digit
                let next = input.index(after: index)
                if next < input.endIndex && input[next].isNumber {
                    hasDecimal = true
                    index = input.index(after: index)
                } else {
                    break
                }
            } else if (char == "e" || char == "E") && !hasExponent {
                hasExponent = true
                index = input.index(after: index)
                if index < input.endIndex && (input[index] == "+" || input[index] == "-") {
                    index = input.index(after: index)
                }
            } else {
                break
            }
        }

        if index > input.startIndex {
            let number = String(input[input.startIndex..<index])
            return (Token(text: number, type: .number), input[index...])
        }

        return nil
    }

    // MARK: - Identifier Matching

    private func tryMatchIdentifier(_ input: Substring, keywords: Set<String>) -> (Token, Substring)? {
        guard let firstChar = input.first else { return nil }

        // Check if starts with letter or underscore
        guard firstChar.isLetter || firstChar == "_" else { return nil }

        var index = input.index(after: input.startIndex)
        while index < input.endIndex {
            let char = input[index]
            if char.isLetter || char.isNumber || char == "_" {
                index = input.index(after: index)
            } else {
                break
            }
        }

        let identifier = String(input[input.startIndex..<index])
        let rest = input[index...]

        // Determine token type
        let tokenType: TokenType
        if keywords.contains(identifier) {
            tokenType = .keyword
        } else if identifier.first?.isUppercase == true {
            tokenType = .type
        } else if rest.first == "(" {
            tokenType = .function
        } else {
            tokenType = .plain
        }

        return (Token(text: identifier, type: tokenType), rest)
    }

    // MARK: - Language Definitions

    private static func keywords(for language: String) -> Set<String> {
        switch language {
        case "swift":
            return swiftKeywords
        case "python", "py":
            return pythonKeywords
        case "javascript", "js":
            return javascriptKeywords
        case "typescript", "ts":
            return typescriptKeywords
        case "java":
            return javaKeywords
        case "c":
            return cKeywords
        case "cpp", "c++", "cxx":
            return cppKeywords
        case "go", "golang":
            return goKeywords
        case "rust", "rs":
            return rustKeywords
        case "ruby", "rb":
            return rubyKeywords
        case "kotlin", "kt":
            return kotlinKeywords
        case "php":
            return phpKeywords
        case "csharp", "cs", "c#":
            return csharpKeywords
        default:
            return []
        }
    }

    private static func commentPatterns(for language: String) -> (line: String?, block: (start: String, end: String)?) {
        switch language {
        case "python", "py", "ruby", "rb":
            return ("#", nil)
        case "swift", "java", "javascript", "js", "typescript", "ts", "c", "cpp", "c++", "cxx",
             "go", "golang", "rust", "rs", "kotlin", "kt", "php", "csharp", "cs", "c#":
            return ("//", (start: "/*", end: "*/"))
        default:
            return ("//", (start: "/*", end: "*/"))
        }
    }

    // MARK: - Keyword Sets

    private static let swiftKeywords: Set<String> = [
        "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch", "class",
        "continue", "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
        "false", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "in", "infix",
        "init", "inout", "internal", "is", "lazy", "let", "mutating", "nil", "nonisolated", "nonmutating",
        "open", "operator", "optional", "override", "postfix", "precedencegroup", "prefix", "private",
        "protocol", "public", "repeat", "required", "rethrows", "return", "self", "Self", "set", "some",
        "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias",
        "unowned", "var", "weak", "where", "while", "willSet", "didSet", "@escaping", "@MainActor",
        "@Sendable", "@available", "@Published", "@State", "@Binding", "@Environment", "@ViewBuilder"
    ]

    private static let pythonKeywords: Set<String> = [
        "False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue",
        "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if", "import",
        "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try", "while",
        "with", "yield", "self", "print"
    ]

    private static let javascriptKeywords: Set<String> = [
        "async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default",
        "delete", "do", "else", "export", "extends", "false", "finally", "for", "function", "if",
        "import", "in", "instanceof", "let", "new", "null", "return", "static", "super", "switch",
        "this", "throw", "true", "try", "typeof", "undefined", "var", "void", "while", "with", "yield",
        "console", "require", "module", "exports"
    ]

    private static let typescriptKeywords: Set<String> = javascriptKeywords.union([
        "abstract", "any", "as", "boolean", "declare", "enum", "implements", "interface", "keyof",
        "namespace", "never", "number", "object", "private", "protected", "public", "readonly",
        "string", "symbol", "type", "unknown"
    ])

    private static let javaKeywords: Set<String> = [
        "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const",
        "continue", "default", "do", "double", "else", "enum", "extends", "false", "final", "finally",
        "float", "for", "goto", "if", "implements", "import", "instanceof", "int", "interface", "long",
        "native", "new", "null", "package", "private", "protected", "public", "return", "short",
        "static", "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient",
        "true", "try", "void", "volatile", "while"
    ]

    private static let cKeywords: Set<String> = [
        "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else",
        "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register",
        "restrict", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef",
        "union", "unsigned", "void", "volatile", "while", "_Bool", "_Complex", "_Imaginary",
        "NULL", "true", "false"
    ]

    private static let cppKeywords: Set<String> = cKeywords.union([
        "alignas", "alignof", "and", "and_eq", "asm", "bitand", "bitor", "bool", "catch", "class",
        "compl", "concept", "consteval", "constexpr", "constinit", "const_cast", "co_await",
        "co_return", "co_yield", "decltype", "delete", "dynamic_cast", "explicit", "export", "friend",
        "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator", "or",
        "or_eq", "private", "protected", "public", "reinterpret_cast", "requires", "static_assert",
        "static_cast", "template", "this", "thread_local", "throw", "try", "typeid", "typename",
        "using", "virtual", "wchar_t", "xor", "xor_eq", "override", "final"
    ])

    private static let goKeywords: Set<String> = [
        "break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough",
        "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range",
        "return", "select", "struct", "switch", "type", "var", "nil", "true", "false", "iota",
        "append", "cap", "close", "complex", "copy", "delete", "imag", "len", "make", "new",
        "panic", "print", "println", "real", "recover"
    ]

    private static let rustKeywords: Set<String> = [
        "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum",
        "extern", "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move",
        "mut", "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait", "true",
        "type", "unsafe", "use", "where", "while", "abstract", "become", "box", "do", "final",
        "macro", "override", "priv", "try", "typeof", "unsized", "virtual", "yield"
    ]

    private static let rubyKeywords: Set<String> = [
        "BEGIN", "END", "alias", "and", "begin", "break", "case", "class", "def", "defined?",
        "do", "else", "elsif", "end", "ensure", "false", "for", "if", "in", "module", "next",
        "nil", "not", "or", "redo", "rescue", "retry", "return", "self", "super", "then", "true",
        "undef", "unless", "until", "when", "while", "yield", "require", "puts", "attr_accessor",
        "attr_reader", "attr_writer", "private", "protected", "public"
    ]

    private static let kotlinKeywords: Set<String> = [
        "abstract", "actual", "annotation", "as", "break", "by", "catch", "class", "companion",
        "const", "constructor", "continue", "crossinline", "data", "do", "else", "enum", "expect",
        "external", "false", "final", "finally", "for", "fun", "get", "if", "import", "in",
        "infix", "init", "inline", "inner", "interface", "internal", "is", "lateinit", "noinline",
        "null", "object", "open", "operator", "out", "override", "package", "private", "protected",
        "public", "reified", "return", "sealed", "set", "super", "suspend", "tailrec", "this",
        "throw", "true", "try", "typealias", "val", "var", "vararg", "when", "where", "while"
    ]

    private static let phpKeywords: Set<String> = [
        "abstract", "and", "array", "as", "break", "callable", "case", "catch", "class", "clone",
        "const", "continue", "declare", "default", "do", "echo", "else", "elseif", "empty",
        "enddeclare", "endfor", "endforeach", "endif", "endswitch", "endwhile", "eval", "exit",
        "extends", "false", "final", "finally", "fn", "for", "foreach", "function", "global",
        "goto", "if", "implements", "include", "include_once", "instanceof", "insteadof",
        "interface", "isset", "list", "match", "namespace", "new", "null", "or", "print", "private",
        "protected", "public", "readonly", "require", "require_once", "return", "static", "switch",
        "throw", "trait", "true", "try", "unset", "use", "var", "while", "xor", "yield"
    ]

    private static let csharpKeywords: Set<String> = [
        "abstract", "as", "base", "bool", "break", "byte", "case", "catch", "char", "checked",
        "class", "const", "continue", "decimal", "default", "delegate", "do", "double", "else",
        "enum", "event", "explicit", "extern", "false", "finally", "fixed", "float", "for",
        "foreach", "goto", "if", "implicit", "in", "int", "interface", "internal", "is", "lock",
        "long", "namespace", "new", "null", "object", "operator", "out", "override", "params",
        "private", "protected", "public", "readonly", "ref", "return", "sbyte", "sealed", "short",
        "sizeof", "stackalloc", "static", "string", "struct", "switch", "this", "throw", "true",
        "try", "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using", "var",
        "virtual", "void", "volatile", "while", "async", "await", "dynamic", "nameof", "when"
    ]
}
