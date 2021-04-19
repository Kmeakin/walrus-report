# Implementation

## The pipeline
TODO: a nice diagram of information flow

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
Once a flat stream of tokens has been produced, they must be assembled into a
more structured tree-like structure, where each syntatic construct is a child of
its enclosing construct (with a whole file forming the root node). For example,
this Walrus file 
```rust
fn square(x: Int) -> Int {
    x * x
}
```
would then produce this parse tree:
```{.graphviz}
digraph {
    1 [label="SourceFile"]
    2 [label="FnDef"]
    3 [label="KwFn"]
    4 [label="Ident"]

    5 [label="ParamList"]
    6 [label="LParen"]
    7 [label="Param"]
    8 [label="VarPat"]
    9 [label="Colon"]
    10 [label="VarType"]
    11 [label="RParen"]

    12 [label="RetType"]
    13 [label="ThinArrow"]
    14 [label="VarType"]

    15 [label="BlockExpr"]
    16 [label="LCurly"]
    17 [label="BinopExpr"]
    18 [label="VarExpr"]
    19 [label="Mul"]
    20 [label="VarExpr"]
    21 [label="RCurly"]

    1 -> 2
    2 -> {3, 4, 5, 12, 15}
    5 -> {6, 7, 11}
    7 -> {8, 9, 10}
    12 -> {13, 14}
    15 -> {16, 17, 21}
    17 -> {18, 19, 20}
}
```

### Parsing approaches
The task of parsing is significantly more complex than lexing. Lexing is largely
considered a "solved problem" with lexer-generators capable of generating lexers
just as fast, if not faster, than any written by an experienced programmer. By
contrast, there are numerous competing approaches to parsing, each with their
own advantages and disadvantages ^[For a good overview of commonly used parsing
approaches, see
https://tratt.net/laurie/blog/entries/which_parsing_approach.html]. In the
course of writing the Walrus compiler, I have experiemented with 4 different
parsing approaches: the parser is by far the most rewritten component of the
Walrus compiler, and still the component I am least satisfied with.

#### LR parser-generators {#sec:impl:parser:lr}
LALR (lookahead left-to-right) parser generators generate a parser from a
description of a grammar, usually in (Extended) Backus-Naur Form. These tools
produce a *table-driven* parser: the parser consists of a table of *states* and
corresponding *actions* for each token at each state: whether to *shift* (read
in another token of input), *reduce* (create a new syntax node) or *accept*
(finish parsing). 

LR parsers are able proven to be able to parse a large class of possible
context-free languages, and tend to be very fast. For this reason they are given
great prominence in university compiler courses. However, LR parser-generators
one great weakensses: LR-parser generators will only accept grammars that are in
a LR-compatible form. Grammars that do not conform to this expected style will
generally cause the parser generator to give inscruitable errors related to
*shift-reduce* errors. For example, attempting to pass the following grammar:
```
%start Expr
%%
Expr: Expr "-" Expr
    | Expr "*" Expr
    | "INT"
    ;
```
to the venerable `Yacc` produces:
```
expr1.y: yacc finds 4 shift/reduce conflicts
```
which is incomprehensible unless the user is familiar with the underlying LR
algorithm. The root cause is that the grammar is *ambigous*: the same imput
string can be parsed in more than one way. For example, the string `1 - 2 - 3`
could be parsed as either `(1 - 2) - 3` or `1 - (2 - 3)`. The workaround to this
is to rewrite the grammar as
```
%start Expr
%%
Expr: Expr ("+" | "-") Term
    | Term
    ;
Term: Term ("*" | "/") Factor
    | Factor
    ;
Factor: "INT"
    ;
```
While the solution seems simple for this small example, naively copying a
context-free grammar of a real life programming language into a LR-parser
generator will produce hundreads of such shift-reduce conflicts, and the
resulting fixed grammar will be contorted beyond recognition.

LR parser generators were my first attempt at writing a parser for Walrus (in
particular, using the LALRPOP parser generator ^[See
https://github.com/lalrpop/lalrpop]), however I quickly became frustrated by the
need to contort my grammar to meet the expectations of the parser generator, and
so moved onto the next attempt:

#### Handwritten recursive descent {#sec:impl:parser:recursive-descent}
A handwritten recursive descent parser is simply a series of functions
representing each nonterminal in the language grammar. In this sense
recursive-descent is the simplest form of parsing: no intermediate tool or
domain-specific language is needed; instead, one simply writes in the same
programming language that they would use for any other task. The only caveat is
that care must be taken to ensure that operator precedences and associativities
are correctly handled, and that the resulting program is not
*left-recursive* (it attempts to parse the same non-terminal repeatedly without
consuming any tokens between each call), otherwise it will loop-forever/crash
witha stack-overflow.

In recent years, *error recovery* has become an important consideration
when writing a parser for a modern compiler. This is because one of the main
determinants of a compiler's user-experience is the *edit-compile-run cycle*
^[Also called the *write-compile-debug cycle*, amongst other names]: the loop
between writing new code, compiling it, realising it has syntactic or semantic
errors, correcting the errors, and recompiling. The more errors (both syntactic
and semantic) that can be detected in a single compiler invocation, the fewer
trips around this cycle will be required, and so the more satisfied the
developer will be. Therefore it is crucial that a production compiler does not
abort on the first encountered syntax error: it should be able to continue
parsing the rest of the file to detect more syntax errors, and potentially even
perform semantic analysis to detect any semantic errors in code that was
succesfully parsed. Error recovery is an ongoing research problem, and so far no
parser generator seems to be able to produce a parse tree even in the presence
of several syntax errors. For this reason, the 2 most popular C compilers, GCC
and Clang, as well as the rust compiler, rustc, all use handwritten recursive
descent parsers that go to great pains to always recover in the presence of
syntax errors.

I attempted for a few weeks to add error recovery to my own handwritten
recursive descent parser. However, writing a parser that can both recover from
all possible syntax errors and still accept correct programs is a time-consuming
and difficult process, and I realised that I risked sinking too much time trying
to achieve the perfect parser without moving onto the rest of the compiler
implementation.

#### Parsing expression grammars {#sec:impl:parser:peg}
TODO PEGs were first introduced by ??? in ???

Parsing-expression grammars (PEGs) also describe a recursive-descent parser,
however rather than writing the parser by hand, a corresponding function is
generated for each *rule* in the grammar. These rules have syntax very similar
to that of Backus-Naur Form, however the *choice operator*, `|`, is replaced by
the *ordered-choice operator*, `/`. Rather than nondeterministically selected
the "most appropriate" alternative to parse with, the ordered-choice operator
selects the first alternative that suceeds and sticks with it, even if
subsequent parsing fails. This results in the problem of ambigious grammars
being defined out of existance, since every string will be parsed in exactly one
way.

For example, the same grammar as given in @sec:impl:parser:lr would be:
```
Expr <- Term (("+" / "-") Term)*
Term <- Factor (("*" / "/") Factor)*
Factor <- INT
```

This generates a similar set of mutually recursive functions as one would write
if they were writing a recursive descent parser by hand, but retains the
advantage of being declarative and easier to maintain. I was satisfied with the
PEG implementation of the Walrus parser for quite some time, however I
eventually grew frustrated with PEGs. Because PEGs are, like
LR-parser-generators, a *domain-specific-language*, their abstract abilities are
limited by whatever facilities the designer of the language thought to include.
For example, although you can define a rule for parsing a tuple of expressions,
and another rule for parsing a tuple of patterns, and a third for parsing a
tuple of types:

```
TupleExpr <- LParen (Expr (Comma Expr)*)? Comma? RParen
TuplePat <- LParen (Pat (Comma Pat)*)? Comma? RParen
TupleType <- LParen (Type (Comma Type)*)? Comma? RParen
```

there is no way of abstracting over the "parse a comma separated list of
elements between two parentheses" part and substituting in the element of the
tuple to be parsed. In other words, we need *higher-order* rules: functions that
take in one rule and produce another rule. Hence I abandoned PEGs in favour of
parser-combinators.

#### Parser combinators {#sec:impl:parser:parser-combinators}
TODO Parser-combinators were first introduced by ??? in ???

## Lowering

## Scopes

## Type inference

## Codegen

### Runtime value representation

## Command-line interface