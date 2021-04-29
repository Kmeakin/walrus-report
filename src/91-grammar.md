## Grammar {#sec:appendix:grammar}

\setlength{\grammarindent}{12em}

TODO: explain how to interpret
https://www.w3.org/TR/xml/#sec-notation

### Trivia
Whitespace and comments are classified as *trivia*. All trivia tokens are
stripped out of the token stream before they are consumed by the parser.

\begin{grammar}
<Whitespace> ::= <Any Unicode character with the property White_Space>

<Comment> ::= <LineComment> | <BlockComment>

<LineComment> ::= "//" <Any Unicode character except newline>*

<BlockComment> ::= "/*" <Any Unicode character> <BlockComment>? <Any Unicode character>* "/*"
\end{grammar}

### Identifiers
\begin{grammar}
<Ident> ::= <IdentStart> <IdentContinue>*
       \alt "_" <IdentContinue>*

<IdentStart> ::= <Any Unicode character with the property XID_Start>

<IdentContinue> ::= <Any Unicode character with the property XID_Continue>
\end{grammar}

### Definitions
\begin{grammar}
<Program> ::= <Decl>*

<Def> ::= <FnDef> | <StructDef> | <EnumDef>

<FnDef> ::= "fn" <Ident> "(" <Param>,* ")" ("->" <Type>)? <BlockExpr>

<Param> ::= <Pat> (":" <Type>)?

<StructDef> ::= "struct" <Ident> "{" <StructField>,* "}"

<StructField> ::= <Ident> ":" <Type>

<EnumDef> ::= "enum" <Ident> "{" <EnumVariant>,* "}"

<EnumVariant> ::= <Ident> "{" <StructField>,* "}"
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

<FloatLit> ::= <DecLit> "." <DecLit>

<CharLit> ::= "'" <Any Unicode character except \\ or '> "'"
         \alt "'" <EscapeChar> "'"
         \alt "'" <UnicodeChar> "'"

<EscapeChar> ::= "\\n" | "\\r" | "\\t" | "\\0" | "\\'" | "\\\"" | "\\\\"

<UnicodeChar> ::= "\\u{" <HexDigit> <HexDigit_>* "}"

<StringLit> ::= "\"" <StringChar>* "\""

<StringChar> ::= <Any Unicode character except \\ or ">
            \alt <EscapeChar>
            \alt <UnicodeChar>
\end{grammar}

### Expressions
\begin{grammar}
<Expr> ::= <LitExpr>
      \alt <VarExpr>
      \alt <ParenExpr>
      \alt <TupleExpr>
      \alt <StructExpr>
      \alt <EnumExpr>
      \alt <FieldExpr>
      \alt <UnopExpr>
      \alt <BinopExpr>
      \alt <CallExpr>
      \alt <LambdaExpr>
      \alt <ReturnExpr>
      \alt <BreakExpr>
      \alt <ContinueExpr>
      \alt <MatchExpr>
      \alt <IfExpr>
      \alt <LoopExpr>
      \alt <BlockExpr>

<LitExpr> ::= <Lit>

<VarExpr> ::= <Ident>

<ParenExpr> ::= "(" <Expr> ")"

<TupleExpr> ::= "(" ")"
           \alt "(" <Expr> "," ")"
           \alt "(" <Expr> "," <Expr>,+ ")"

<StructExpr> ::= <Ident> "{" <InitExpr>,* "}"

<EnumExpr> ::= <Ident> "::" <Ident> "{" <InitExpr>,* "}"

<InitExpr> ::= <Ident> ":" <Expr>
          \alt <Ident>

<FieldExpr> ::= <Expr> "." <Ident>
           \alt <Expr> "." <DecLit>

<UnopExpr> ::= <Unop> <Expr>

<Unop> ::= "+" | "-" | "!"

<BinopExpr> ::= <Expr> <Binop> <Expr>

<Binop> ::= "+" | "-" | "*" | "/" | "=" | "==" | "!=" | "<" | "<=" | ">" | ">=" | "&&" | "||"

<CallExpr> ::= <Expr> "(" <Expr>,* ")"

<LambdaExpr> ::= "(" <Param>,* ")" "=>" <Expr>

<ReturnExpr> ::= "return" <Expr>?

<BreakExpr> ::= "break" <Expr>?

<ContinueExpr> ::= "continue"

<MatchExpr> ::= "match" <ExprNoStruct> "{" <MatchCase>,* "}"

<MatchCase> ::= <Pat> "=>" <Expr>

<ExprNoStruct> ::= <Expr except StructExpr or EnumExpr>

<IfExpr> ::= "if" <ExprNoStruct> <BlockExpr> <ElseExpr>?

<ElseExpr> ::= "else" <IfExpr>
          \alt "else" <BlockExpr>

<LoopExpr> ::= "loop" <BlockExpr>

<BlockExpr> ::= "{" <Stmt>,* <Expr>? "}"

<Stmt> ::= <LetStmt> 
      \alt <ExprStmt> 
      \alt <BlockLikeExprStmt> 
      \alt ";"

<LetStmt> ::= "let" <Pat> ":" <Type> "=" <Expr> ";"
         \alt "let" <Pat> "=" <Expr> ";"

<ExprStmt> ::= <Expr except MatchExpr, IfExpr, LoopExpr or BlockExpr> ";"

<BlockLikeExprStmt> ::= <MatchExpr> | <IfExpr> | <LoopExpr> | <BlockExpr>
\end{grammar}

### Patterns
\begin{grammar}
<Pat> ::= <LitPat>
     \alt <VarPat>
     \alt <IgnorePat>
     \alt <ParenPat>
     \alt <TuplePat>
     \alt <StructPat>
     \alt <EnumPat>

<LitPat> ::= <Lit>

<IgnorePat> ::= "_"

<VarPat> ::= <Ident>

<ParenPat> ::= "(" <Pat> ")"

<TuplePat> ::= "(" ")"
           \alt "(" <Pat> "," ")"
           \alt "(" <Pat> "," <Pat>,+ ")"

<StructPat> ::= <Ident> "{" <FieldPat>,* "}"

<EnumPat> ::= <Ident> "::" <Ident> "{" <FieldPat>,* "}"

<FieldPat> ::= <Ident> ":" <Pat>
          \alt <Ident>
\end{grammar}

### Types
\begin{grammar}
<Type> ::= <VarType>
      \alt <InferType>
      \alt <ParenType>
      \alt <TupleType>
      \alt <FnType>

<VarType> ::= <Ident>

<InferType> ::= "_"

<ParenType> ::= "(" <Type> ")"

<TupleType> ::= "(" ")"
           \alt "(" <Type> "," ")"
           \alt "(" <Type> "," <Type>,+ ")"

<FnType> ::= "(" <Type>,* ")" "->" <Type>
\end{grammar}
