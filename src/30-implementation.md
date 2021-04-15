# Implementation

## The pipeline

## Lexing
Before the text of a program can be parsed into a parse tree, it must be first
split into a flat stream of *tokens*: chunks of text with a label classifying
their role in parsing, such as `whitespce`, `identifier`, `string literal`.

For example, the Walrus code
```rust
fn main() {
    print("Hello, world!\n");
}
```

would be lexed as:
```
KwFn
Whitespace
Ident
LParen
RParen
Whitespace
LCurly
Whitespace
Ident
LParen
String
RCurly
Semicolon
Whitespace
RCurly
```

The tokens of a programming language are often simple enough to be expressed as
a *regular language*. That is, they can be recognised by a *finite state
machine*. As a general rule, when recognising languages, it is good practice to
use the model of computation that is just powerful enough to recognise the
language in question, but not more. Therefore, although a lexer could be written
by hand in the Turing-complete language Rust, this is overkill when a
finite-state-machine can do the job adequately ^[The lexical structure of Walrus
is not quite regular, as its block-comments are in fact context-free, but this
can be adjusted by a minor addition to the lexer, which will be exlained later
in this section].

The job of lexing Walrus code was therefore delegated to the excellent
lexer-generator `Logos` ^[See https://github.com/maciejhirsz/logos]. `Logos`
accepts a description of a language's lexical syntax expressed via a
*regular-expression* matching each token, and generates an optimised Rust
program to perform the lexical analysis. `Logos` also allows providing a
handwritten function to lex a single token, when that token's structure cannot
be expressed as a regular-expression: this is what we use to lex nested
block-comments, which are context-free, not regular. By using a lexer-generator,
we can keep the implementation of the lexer small and easy to maintain, whilst
still getting a lexer that is just as fast as an optimised hand-written
implementation. All that the compiler writer need provide is a few dozen lines
of glue code to drive the lexer and attatch start and end indicies to each
token. See @sec:appendix:lexer for the full implementation of the Walrus lexer.

## Parsing

## Lowering

## Scopes

## Type inference

## Codegen

### Runtime value representation
