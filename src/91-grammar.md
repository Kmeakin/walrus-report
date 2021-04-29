## Grammar {#sec:appendix:grammar}

\setlength{\grammarindent}{10em}

https://www.w3.org/TR/xml/#sec-notation

### Trivia
Whitespace and comments are classified as *trivia*. All trivia tokens are
stripped out of the token stream before they are consumed by the parser.

\begin{grammar}
<Whitespace> ::= <Any Unicode character with the property White_Space>

<Comment> ::= <LineComment> | <BlockComment>

<LineComment> ::= "//" <Any Unicode character other than newline>*

<BlockComment> ::= "/*" <Any Unicode character> <BlockComment>? <Any Unicode character>* "/*"
\end{grammar}

### Identifiers
\begin{grammar}
<Ident> ::= <IdentStart> <IdentContinue>*
       \alt <Underscore> <IdentContinue>*

<IdentStart> ::= <Any Unicode character with the property XID_Start>

<IdentContinue> ::= <Any Unicode character with the property XID_Continue>

<Underscore> ::= "_"
\end{grammar}

### Definitions
\begin{grammar}
<Program> ::= <Decl>*

<Def> ::= <FnDef> | <StructDef> | <EnumDef>

<FnDef> ::= "fn" <Ident> <ParamList> <RetType>? <BlockExpr>

<StructDef> ::= "struct" <Ident> <StructFields>

<StructFields> ::= "{" <StructField>,* "}"

<StructField> ::= <Ident> ":" <Type>

<EnumDef> ::= "enum" <Ident> "{" <EnumVariant>,* "}"

<EnumVariant> ::= <Ident> <StructFields>
\end{grammar}

### Literals
\begin{grammar}
<BoolLit> ::= "true" | "false"

<IntLit> ::= <DecLit> | <BinLit> | <HexLit>

<DecLit> ::= <DecDigit> <DecDigit_>*

<DecDigit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"

<DecDigit_> ::= <DecDigit> | "_"

<BinLit> ::= <BinDigit> <BinDigit_>*

<BinDigit_> ::= <BinDigit_> | "_"

<BinDigit> ::= "0" | "1"

<HexLit> ::= <HexDigit> <HexDigit_>*

<HexDigit> ::= <DecDigit> 
\alt "a" | "b" | "c" | "d" | "e" | "f"
\alt "A" | "B" | "C" | "D" | "E" | "F"

<HexDigit_> ::= <HexDigit> | "_"
\end{grammar}

### Expressions

### Patterns

### Types