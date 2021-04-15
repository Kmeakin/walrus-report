# Appendix {#sec:appendix}
## Lexer {#sec:appendix:lexer}

```rust
#[derive(Logos)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TokenKind {
    #[error] Error,
    #[regex(r"\s+")] Whitespace,
    #[regex(r"//[^\n]*")] LineComment,
    #[token(r"/*", lex_block_comment)] BlockComment,

    #[token("break")] KwBreak,
    #[token("continue")] KwContinue,
    #[token("else")] KwElse,
    #[token("enum")] KwEnum,
    #[token("false")] KwFalse,
    #[token("fn")] KwFn,
    #[token("if")] KwIf,
    #[token("let")] KwLet,
    #[token("loop")] KwLoop,
    #[token("match")] KwMatch,
    #[token("mut")] KwMut,
    #[token("return")] KwReturn,
    #[token("struct")] KwStruct,
    #[token("true")] KwTrue,

    #[regex(r"(\p{XID_Start}|_)\p{XID_Continue}*")] Ident,
    #[regex(r"[0-9][0-9_]*")]         DecInt,
    #[regex(r"(0b|0B)[0-1][0-1)]*")]  BinInt,
    #[regex(r"(0x|0X)[0-9a-fA-F][0-9a-fA-F_]*")]  HexInt,
    #[regex(r"[0-9][0-9_]*\.[0-9][0-9_]*")] Float,
    #[regex(r"'[^']'")]                              SimpleChar,
    #[regex(r"'\\.'")]                               EscapedChar,
    #[regex(r"'\\(u|U)\{[0-9a-fA-F][0-9a-fA-F_]*\}'")] UnicodeChar,
    #[regex(r#""([^"]|\\")*""#)] String,

    #[token("(")] LParen,
    #[token(")")] RParen,
    #[token("{")] LCurly,
    #[token("}")] RCurly,

    #[token(".")] Dot,
    #[token(",")] Comma,
    #[token(";")] Semicolon,
    #[token(":")] Colon,
    #[token("::")] ColonColon,
    #[token("->")] ThinArrow,
    #[token("=>")] FatArrow,
    #[token("_")] Underscore,

    #[token("+")] Plus,
    #[token("-")] Minus,
    #[token("*")] Star,
    #[token("/")] Slash,

    #[token("!")] Bang,
    #[token("&&")] AndAnd,
    #[token("||")] OrOr,

    #[token("=")] Eq,
    #[token("==")] EqEq,
    #[token("!=")] BangEq,
    #[token("<")] Less,
    #[token("<=")] LessEq,
    #[token(">")] Greater,
    #[token(">=")] GreaterEq,
}

fn lex_block_comment(lexer: &mut Lexer) {
    const OPEN: &str = "/*";
    const CLOSE: &str = "*/";

    let mut level = 1;
    while level > 0 && !lexer.remainder().is_empty() {
        let src = lexer.remainder();

        if src.starts_with(OPEN) {
            level += 1;
            lexer.bump(OPEN.len());
        } else if src.starts_with(CLOSE) {
            level -= 1;
            lexer.bump(CLOSE.len());
        } else {
            lexer.bump(src.chars().next().unwrap().len_utf8())
        }
    }
}

#[derive(Copy, Clone, PartialEq)]
pub struct Token<'a> {
    pub span: Range<usize>,
    pub kind: TokenKind,
    pub text: &'a str,
}

pub fn lex(src: &str) -> impl Iterator<Item = Token> {
    let mut lexer = Lexer::new(src);
    iter::from_fn(move || {
        let kind = lexer.next()?;
        let text = lexer.slice();
        let span = lexer.span();
        Some(Token { span, kind, text })
    })
}
```
