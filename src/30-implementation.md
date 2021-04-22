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
parser combinators.

#### Parser combinators {#sec:impl:parser:parser-combinators}
Parser combinators may be considered as functional programming applied to the
traditional imperative recursive-descent parser. Parser combinators were first
introduced for Haskell by Phil Wadler in 1995 as a demonstration of the power of
monads for functional programming ^[TODO: citation], and have since been adapted
to many other programming languages. 

In Rust,a parser is any type that provides a way to parse an input, `I`, into an
`Option<(I, O)>`, where `None` represents the parser failing, and `Some(I, O)`
represents the parser succeeding and returning the rest of the input to be
parsed, along with some output (such as a new node in the parse tree)

```rust
trait Parser<I, O> {
    fn parse(&mut self, input: I) -> Option<(I, O)>;
}
```

As well as primitive parsers to parse single characters, strings, or tokens,
there are *parser-combinators*, higher order functions that return new parsers,
such as `many0` to attempt to parse the input as many times as possible, or
`opt`, to attempt to parse the input 0 or 1 times. Since combinators are normal
functions, the user is free to write their own arbitrarily complex parsers. For
example, here is the `tuple` combinator from the Walrus parser, which wraps a
parser `p` into a parser that parses a tuple of `Element`s:

```rust
fn tuple<P, Element>(p: P) -> impl Parser<Tokens, Tuple<Element>> 
where
    P: Parser<Tokens, Element>
{
    |input| {
        let (input, lparen) = lparen.parse(input)?;
        let (input, elements) = p.then(comma.then(p).many0()).opt()?;
        let (input, trailing_comma) = comma.opt.parse()?;
        let (input, rparen) = rparen.parse(input)?;
        Some((input, Tuple{lparen, elements, trailing_comma, rparen}))
    }
}
```

Of the 4 approaches I have explored in writing the Walrus parser, I find parser
combinators to be the most satisfactory: they are nearly as declarative as
Parsing Expression Grammars, whilst still allowing the programmer to use the
full abstraction capabilities of the normal implementation language, as in
hand-written recursive descent. However, the implementation is still far from
satisfactory: it provides neither error reporting nor error recovery. Since my
parser combinators currently do not distingush between failure to parse due to a
syntax error and failure to parse because another alternative rule needs to be
attempted, the precise location of a syntax error cannot easily be detected -
the only indication that a syntax error was encountered was that the whole input
string was not consumed. Therefore, the Walrus parser will simply abort if the
entire input file is not consumed, without any indication of where the first
syntax error occurred. Error-reporting and error-recovering parser-combinators
would be one of my first priorities if I were to continue working on the
compiler.

## Semantic Analysis
The two previous sections have covered *syntactic-analysis*: ensuring that the
program is *syntatically-correct*. Now we will move onto *semantic-analysis*:
checking that the program is *semantically-correct* (it contains no type errors,
all referenced variables are defined, etc), and gathering enough information to
be able to generate LLVM IR if the program is indeed semantically-correct.

### Lowering
Before we can begin performing semantic-analysis, we must convert the parse-tree
which was generated by the parser to a more suitable Intermediate
Representation. This is because the parse-tree contains a lot of extraenous
nodes to represent syntactic elements such as commas and parentheses which carry
no semantic information. The parse-tree also carries the source-location of
every node. This is useful for display the source location of errors to the
programmer, but is only needed once semantic-analysis has been performed and all
errors have been collected - while actual semantic analysis takes place, we do
not need this extra information.

For these reasons, when performing semantic-analysis we operate over a more
abstracted, high level representation, named unimaginatively the High-level
Intermediate Representation. This name was inherited from the rustc compiler,
which has several IRs, including a High-level Intermediate Representation and a
Mid-level Intermediate Representation. ^[Some textbooks and compilers name the
IR they perform semantic analysis over the "Abstract Syntax Tree", however I
have chosen to avoid that name as it may be confused for the parse-tree produced
by a parser, which is also sometimes called an "Abstract Syntax Tree"]. The
process of converting a parse tree to its HIR is called *lowering*.

In Walrus, the HIR of a program is represented by several mutually recursive
structs (see @sec:appendix:hir), the most important being `FnDef`, `StructDef`,
`EnumDef`, `Expr`, `Pat` and `Type`. 

#### HIR annotation
Having a representation of the all the source level entities - expressions,
types, patters etc, is not sufficient for performing semantic analysis. We also
need a way to associate each entity with certain semantic information that is
produced and consumed during semantic analysis and code generation - for
example, each expression must be associated with its inferred type after type
inference, or each variable with its parent scope. This problem of having to
annotate trees with different peices of metadata at different stages in a
program has been referred to in the literature as *The AST Typing Problem* ^[BIB
http://blog.ezyang.com/2013/05/the-ast-typing-problem] or the *The tree
Decoration Problem* ^[BIB Trees that Grow paper].

The naive solution to this problem is to have multiple IRs for each stage of the
semantic analysis and annotate each new IR with the appropriate information, so
that, for example, scope-checking converts `Expr`s to `ScopedExpr`s and
type-inference converts `ScopeExpr`s to `TypedExprs`. However, this approach
would require a large amount of code duplication: the HIR definitions given in
@sec:appendix:hir run to about 250 lines, so each new IR woudld add at least 250
lines of nearly identitical struct definitions plus code to convert between the
representations.

The approach we have chosen is to store auxiallary data in *side-tables* (eg a
`HashMap` or other associative container), rather than storing them *inline*
inside the tree data structure. For example, as a first attempt, we could create
a `HashMap<hir::Expr, types::Type>`{.rust}, for mapping each `Expr` to its
inferred `Type` ^[`hir::Type`, should not be confused with `types::Type`. The
first represents types as they appear in the surface syntax. The latter
represents type values]. However, this is not quite correct, as this would
hash each node based on its *value*, not its *identity*. Consider type checking
the following snippet of code:

```rust
fn f(x: Int) {
    let x = x + x;
    let x = int_to_string(x);
    print(x);
}
```

In this function, the variable `x` appears 7 times in different locations, and
each occurance of the variale `x` may require different information to be
associated with it (eg each occurance of `x` should have a distinct source
location for reporting errors, and may potentially have a different inferred
type as new variables shadow old ones). The solution is to use an
*arena-allocation strategy*: the HIR nodes themselves are stored in `Vec`
(Rust's dynamic array type), and the index of the node into the arena is used to
provide identity semantics. The `Vec` that holds each type of HIR node is
refered to as the *arena*, and the index into the arena is the node's *ID*:

```rust
struct Id<T> {
    index: usize,
    ty: PhantomData<T>,
}

type ExprId = Id<Expr>;
```

### Name resolution {#sec:impl:scopes}
Any non-trivial semantic analysis over the HIR will require us to be able to
*resolve-names*: lookup the entity (if any) that a variable name refers to in a
given scope. Since a variable can refer to one of many different named entities
(local variables, functions, structs, enums, builtin types and builtin
functions), we say that a variable name has a corresponding *denotation*, since
this name is more general than *value*, which could refer simply to runtime
values.

```rust
pub enum Denotation {
    Local(VarId),
    Fn(FnDefId),
    Struct(StructDefId),
    Enum(EnumDefId),
    Builtin(Builtin),
}
```

Name resolution is performed by calculating the set of nested *scopes* for the
whole program. Each `Scope` contains a `HashMap<String, Denotation>`{.rust}
mapping each variable to its corresponding denotation, and an optional pointer
to its parent `Scope` (the root scope has no parent). The tree of scopes is then
calculated by performing a depth-first walk over the HIR tree, inserting
corresponding `Denotation`s as new definitions are introduced, and emitting an
error if a variable is introduced that is already defined in the same scope.
Lexical scope is achieved by entering a new `Scope` at every construct that
introduces new local variables (let statements, function parameter lists, lambda
expression parameter lists, `match` cases)

For example, this program
```rust
fn main() {
    let x = 5;
    f(S{x: x + x}, x);
}
 
fn f(s: S, x: Int) -> S {
    let x = 5;
    let x = 0;
    {
        let s = x;
    }
    s
}
 
struct S {x: Int}
```

produces the following scope tree:
```{.graphviz}
digraph {
    rankdir = BT;
    0
    1 -> 0
    2 -> 1
    3 -> 0
    4 -> 3
    5 -> 4
    6 -> 5
}
```


### Type inference

## Codegen
### Runtime value representation

## Command-line interface