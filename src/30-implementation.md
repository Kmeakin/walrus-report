# Implementation

## The pipeline
TODO: a nice diagram of information flow

## Lexing
Before the text of a program can be parsed into a parse tree, it must be first
split into a flat stream of *tokens*: chunks of text with a label classifying
their role in parsing, such as `Whitespce`, `Identifier`, or `StringLit`.

For example, the Walrus code
```rust
fn main() {
    print("Hello, world!\n");
}
```

would be lexed as:
```
KwFn Whitespace Ident LParen RParen Whitespace LCurly Whitespace Ident
LParen String RCurly Semicolon Whitespace RCurly
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
first represents types as they appear in the abstract syntax. The latter
represents type values]. However, this is not quite correct, as this would hash
each node based on its *value*, not its *identity*. Consider type checking the
following snippet of code:

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
refered to as the *arena*, and the index into the arena is the node's *ID*. Each
`Id<T>`{.rust} is parameterised by the type it represents, even though it does
not store an actual reference or value of type `T`. This provides extra
type-safety over using plain `usize`{.rust}s by preventing an index generated by
an arena of one type being used to index into an arena of another type.

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
expression parameter lists, `match` cases). 

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
\begin{tikzpicture}
% Nodes
\node (Scope0)                          {\makecell[l]{s: Struct(0),\\f: Fn(1),\\main: Fn(0)}};  \node[right=1pt of Scope0] {$scope_{0}$};
\node (Scope1) [below left=of Scope0]   {};                                                     \node[right=1pt of Scope1] {$scope_{1}$};
\node (Scope2) [below=of Scope1]        {\makecell[l]{x: Local(1)}};                            \node[right=1pt of Scope2] {$scope_{2}$};
\node (Scope3) [below right=of Scope0]  {\makecell[l]{s: Local(9), \\x: Local(11)}};            \node[right=1pt of Scope3] {$scope_{3}$};
\node (Scope4) [below=of Scope3]        {\makecell[l]{x: Local(14)}};                           \node[right=1pt of Scope4] {$scope_{4}$};
\node (Scope5) [below=of Scope4]        {\makecell[l]{x: Local(15)}};                           \node[right=1pt of Scope5] {$scope_{5}$};
\node (Scope6) [below=of Scope5]        {\makecell[l]{s: Local(16)}};                           \node[right=1pt of Scope6] {$scope_{6}$};

% Edges
\draw[->] (Scope1) -- (Scope0);
\draw[->] (Scope2) -- (Scope1);
\draw[->] (Scope3) -- (Scope0);
\draw[->] (Scope4) -- (Scope3);
\draw[->] (Scope5) -- (Scope4);
\draw[->] (Scope6) -- (Scope5);
\end{tikzpicture}

It may be more helpful to see the source program annotated with the extent of
each scope:
```rust
// start of scope 0
fn main(/*start of scope 1*/) {
    let x = 5; // start of scope 2 
    f(S{x: x + x}, x);
    // end of scope 2
    // end of scope 1
}
 
fn f(/*start of scope 3*/ s: S, x: Int) -> S {
    let x = 5; // start of scope 4
    let x = 0; // start of scope 5
    {
        let s = x; // start of 6
        // end of scope 6
    }
    s
    // end of scope 5
    // end of scope 4
    // end of scope 3
}
 
struct S {x: Int}
// end of scope 0
```

Once a scope tree has been built, names can be resolved by later passes. Each
variable is mapped to its scope by using a `HashMap<VarId, ScopeId>`{.rust}.
Resolving variables is then done by performing the following search up the scope
tree:

* **step 1**: get the `Var`'s enclosing `Scope`
* **step 2**: lookup the `Var` in the `Scope`'s denotations
* **step 3**: if the `Scope` has no parent, check if there is a builtin function
  or type with the same name. 
  * If there If there is, return the builtin, 
  * else emit an unbound variable error 
* **step 4**: if the `Scope` has a parent, repeat from **step 2**

### Type Inference {#sec:impl:types}
Once we have a scope tree, we can now perform type inference. The type inference
pass produces an `InferenceResult` mapping each HIR entity to its inferred type:

```rust
pub struct InferenceResult {
    pub type_of_var: HashMap<VarId, Type>,
    pub type_of_expr: HashMap<ExprId, Type>,
    pub type_of_type: HashMap<TypeId, Type>,
    pub type_of_pat: HashMap<PatId, Type>,
    pub type_of_fn: HashMap<FnDefId, FnType>,
    pub diagnostics: Vec<Diagnostic>,
}
```

Where a `Type` is either a primitive type, `Uknown`, or various combinations of other types:
```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Type {
    Primitive(PrimitiveType),
    Fn(FnType),
    Struct(StructDefId),
    Enum(EnumDefId),
    Tuple(Vec<Type>),
    Infer(u32),
    Unknown,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum PrimitiveType {
    Bool,
    Int,
    Float,
    Char,
    String,
    Never,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FnType {
    pub params: Vec<Type>,
    pub ret: Box<Type>,
}
```

The `Unknown` type is used as a placeholder when a correct type could not be
inferred, either due to some form of semantic error (such as an unbound
variable), or when there is not enough information available to infer a concrete
type.

#### The algorithm
As explained in @sec:reference:type-system, Walrus' type system is an extension
of the classic Hindley-Milner type system. Type inference for Hindley-Milner
based type systems is simple:

* **Step 1**: Generate a fresh *type-variable* for each type to be inferred (ie
  for each expression, pattern, function, etc)
* **Step 2**: Traverse the program, generating *equality-constraints* between the type
  variables and types according to a set of *type-rules*
* **Step 3**: Solve the system of constraints via *unification* to get a
  *substitution* mapping each type-variable to a type

Consider the following Walrus program:
```rust
fn main() -> _ {
    (p) => if p(1) {2} else {3}
}
```

First, we generate a fresh type-variable for each HIR node. Type variables are
represented simply as an integer which is incremented to generate a fresh
variable:

\begin{tikzpicture}
% Nodes
\node (FnDef)                                   {FnDef};      \node[right=1pt of FnDef]      {$\tau_{0}$};
\node (RetType)     [below right=of FnDef]      {RetType};    \node[right=1pt of RetType]    {$\tau_{9}$};
\node (LambdaExpr)  [below left=of FnDef]       {LambdaExpr}; \node[right=1pt of LambdaExpr] {$\tau_{1}$};
\node (VarPat)      [below left=of LambdaExpr]  {VarPat};     \node[right=1pt of VarPat]     {$\tau_{2}$};
\node (IfExpr)      [below right=of LambdaExpr] {IfExpr};     \node[right=1pt of IfExpr]     {$\tau_{3}$};
\node (CallExpr)    [below left=of IfExpr]      {CallExpr};   \node[right=1pt of CallExpr]   {$\tau_{4}$};
\node (VarExpr)     [below left=of CallExpr]    {VarExpr};    \node[right=1pt of VarExpr]    {$\tau_{5}$};
\node (IntLit1)     [below right=of CallExpr]   {IntLit};     \node[right=1pt of IntLit1]    {$\tau_{6}$};
\node (IntLit2)     [below=of IfExpr]           {IntLit};     \node[right=1pt of IntLit2]    {$\tau_{7}$};
\node (IntLit3)     [below right=of IfExpr]     {IntLit};     \node[right=1pt of IntLit3]    {$\tau_{8}$};

% Edges
\draw[->] (FnDef) -- (LambdaExpr);
\draw[->] (FnDef) -- (RetType);
\draw[->] (LambdaExpr) -- (VarPat);
\draw[->] (LambdaExpr) -- (IfExpr);
\draw[->] (IfExpr) -- (CallExpr);
\draw[->] (IfExpr) -- (IntLit2);
\draw[->] (IfExpr) -- (IntLit3);
\draw[->] (CallExpr) -- (VarExpr);
\draw[->] (CallExpr) -- (IntLit1);
\end{tikzpicture}

TODO: explain how to read the type rules

Then we traverse the HIR to produce a set of equality constraints:

| Constraint                            | Rule applied
|---------------------------------------|--------------
| $\tau_{0} = () \to \tau_{1}$          | FnDef
| $\tau_{1} = \tau_{9}$                 | FnDef
| $\tau_{1} = (\tau_{2}) \to \tau_{3}$  | LambdaExpr
| $\tau_{4} = Bool$                     | IfThenElseExpr
| $\tau_{3} = \tau_{7}$                 | IfThenElseExpr
| $\tau_{3} = \tau_{8}$                 | IfThenElseExpr
| $\tau_{5} = (\tau_{6}) \to \tau_{4}$  | CallExpr
| $\tau_{5} = \tau_{2}$                 | VarExpr
| $\tau_{6} = Int$                      | IntLit
| $\tau_{7} = Int$                      | IntLit
| $\tau_{8} = Int$                      | IntLit

Finally, we solve the set of contraints via *unification*. Unification is the
process of solving a system of symbolic equations by finding a *substitution* a
mapping variables to their values. The unification algorithm required for our
type inference algorithm is relatively simple, since we are only dealing with
equality constraints (symbolic equations of the form $x = y$):

```text
fn unify(constraints: Constraint list) -> Substition {
    if cons is empty, return the empty substitution
    else
        let first_constraint :: rest_constraints = constraints;
        let first_subst = unify1(first_constraint)
        let rest_constraints = replace all variables in rest_constaints by thier values
            in first_subst
        let rest_subst = unify(rest_constraints)
        replace all type in first_subst by thier values in rest_subst
}

fn unify1(ty1: Type, ty2: Type) -> Substition {
    if ty1 and ty2 are both the same primitive type, return the empty substitution
    else if ty1 is a type variable, unify_var(ty1, ty2)
    else if ty2 is a type variable, unify_var(ty2, ty1)
    else if ty1 and ty2 both have the same type constructor, 
        equate the corresponding subtypes of ty1 and ty2 to each other and unify them
    else the two types could not be unified, return an error
}

fn unify_var(ty: Type, var: TypeVar) -> Substition {
    if ty is a type variable
        if ty and var are the same type variable, return the empty substituion
        else return a singleton substution, {var: ty}
    else if var occurs as a variable in ty, return an error
    else return a singleton substution, {var: ty}
}
```

The so-called *occurs-check* in `unify_var` is required to prevent attempting to
construct an infinite type. Consider trying to type check the expression `(f) =>
f(f)`{.rust}. This would generate a constraint of the form $\tau_1 = (\tau_1) \to
\tau_1$, which has no finite solution: attempts to unify the solution would
attempt to construct an infinite type $\tau_1 \to (\tau_1) \to \dots \to
\tau_1$, and cause the unifier to either loop forever or eventually crash due to
a stack overflow, depending on the implementation.

Consider solving the constraint set generated above. We start with an empty
substitution, and remove the first constraint, $\tau_0 = () \to \tau_1$. Since
the left-hand side of the constraint is a type-variable, we add $\tau_0 = ()
\to \tau_1$ to the substitution, and replace all occurences of
$\tau_0$ in the remaining constraints by $() \to \tau_1$ (there are none, so the
constraint set remains unchanged). TODO: repeat this to conclusion in the appendix?

The Walrus type-checker conceptually performs the same steps, however it
interleaves **step 2** and **step 3** by performing unification on demand. This
allows for better error-reporting: messages about unification errors can refer
to the HIR node that was being visited when the unification failed, and be
specialised according to the node: for example, if we discover that the type of
the function in a function-call expression is infact not a function, we can emit
an error of the form "attempted to call a non-function", rather than a more
generic "type mismatch" error. If unification fails, the type of the node is
assumed to be `Type::Unknown` and inference can continue over the rest of the
program, providing better error-recovery.

#### Semantic checks
The type checker pass also checks various other properties of the program as it
traverses the HIR which are difficult to express as equality constraints:

* Every occurence of `break` or `continue` must be within a `loop`
* The left-hand side of an assignment expression must be an *l-value* (see
  @sec:reference:l-values)
* The l-value being assigned to must have been declared mutable with the `mut`
  keyword, and it must refer to a local variable
* Struct or enum patterns must bind all fields, and not refer to nonexistant
  fields
* Field expressions must not attempt to access nonexistant fields
* Patterns in let statements, function parameters or lambda parameters must be
  *irrefutable* (see @sec:reference:irrefutable-patterns)

## Codegen
Once we have finished type inference, we have successfully detected all semantic
errors that could occur in the program, and are ready to generate an executable
file that can be run. For this task we will defer to the LLVM framework. LLVM
handles the intricacies of generating instructions appropriate to the hardware
architecture the progrmam is compiled on and the Application Binary Interface
mandated by the operating system being used. All that we need to do is to
generate *LLVM-IR*. 

### LLVM IR
The LLVM intermediate representation is both low-level enough to allow language
creators fine-grained control over memory layout and language semantics, but
also high-level enough to abstract away platform-specific considerations such as
instruction-set and application-binary-interface (ABI). 

To achieve this, the LLVM IR resembles an assembly programming language, with
the addition of abstractions for compound datatypes, global variables, stack
allocation, and functions. Each LLVM program consists of a series of global
variable definitions, type definitions and function definitions. Unlike
platform-specific programming languges - where the only datatype is a
machine-words (and floating-point types, if the processor supports them) and the
same machines word can be freely reinterpreted as a pointer, an integer, a
character, a boolean, etc by each instruction - LLVM is strongly-typed: each
value has a type, each instruction operates on specified types, and values must
be explictly converted between types. 

Each function body consists of a flat stream of assembly instructions, split
into *basic-blocks* - a continious sequence of instructions, terminated by a
branch or return). Instructions must be in *static single assignment form*
(SSA): each variable must be assigned to exactly once. Mutation is achieved by
storing a value on the stack or heap and writing to the pointed-to value.

### The codegen pass
Generating LLVM IR for a program is accomplished by first generating definitions
for structs, enums and functions, and then generating the body of each function
by a recursive traversal of the function's HIR. The LLVM library provides a
convenient builder API for generating LLVM IR programmatically, rather than
having to format strings with the correct syntax.

#### Literals
##### `Bool`s {#sec:impl:llvm:bools}
Since there are only 2 possible `Bool` values, `true` and `false`, a `Bool`
value can be represented as a single bit at runtime (with `false` mapping to `0`
and `true` to `1`). LLVM IR allows arbitrary-width
integer types &[That is, the width of integer type is still fixed, but is not
restricted to powers of two. LLVM does *not* have in built support for
*arbirary-precision* or so-called "bignum" integers, where the number of bits
occupied by the value is not known at compile-time]. Therefore, each `Bool` can
be represented by the LLVM `i1` type: a 1-bit integer. When translating to
machine-code, LLVM will map this to an 8-bit byte.

##### `Int`s {#sec:impl:llvm:ints}
`Int`s are simply represented as the LLVM `i32` type as-is: no further
processing is needed. `Int`s are stored in memory as twos-complement's integers,
and occupy 4 bytes each. The builtin arithmetic and comparison operators on
`Int`s map directly to LLVM `add`, `sub`, `cmp` etc instructions.

##### `Float`s {#sec:impl:llvm:floats}
`Float`s are simply represented as the LLVM `f32` type as-is: no further
processing is needed. `Float`s are stored in memory according to the binary32
format, and occupy 4 bytes of memory. The builtin arithmetic and comparison
operators on `Float`s map directly to LLVM `fadd`, `fsub`, `fcmp` etc
instructions.

##### `Char`s {#sec:impl:llvm:chars}
Each single `Char` is a 'Unicode Scalar Value': that is any 'Unicode Code Point'
except for high and low surrogates, which are only needed in UTF-8 encodings. In
terms of memory representation, this corresponds to any integer value between
$0$ and $D7FF_{16}$ or $E000_{16}$ and $10FFFF_{16}$, inclusive. This means
that, like `Int`s, `Char`s are represented as LLVM `i32` integers. A consequence
of this representation is that every `Char` value occupies 4 bytes in memory,
even if it is an ASCII character that could fit within 1 byte.

##### `String`s {#sec:impl:llvm:strings}
Unlike `Bool`, `Int`, `Float` and `Char`, LLVM does not provide a builtin string
type. We must decide for ourselves how to represent the contents of a `String`
in memory. Recall that Walrus `String`s can represent any valid sequence of
Unicode characters (see @sec:reference:strings), and so we must choose a scheme
for translating 32-bit Unicode Code Points into a series of 8-bit bytes.

There are 3 possible schemes, depending on the size of each Code Unit. UTF-32
encodes each Code Point as a single 32-bit Code Unit, even if it could fit in a
single byte. UTF-16 encodes each Code Point as 1 or more 16-bit Code Units, and
suffers from the same problem as UTF-16, in that ASCII characters that could be
optimally represented as a single byte occupy 2 bytes. Only UTF-8 does not have
this overhead: ASCII characters are stored exactly as they would be in a legacy
ASCII string. Only Code Points greater than $FF_{16}$ will be encoded as
multiple 8-bit Code Units. For this reason, Walrus uses UTF-8 for its `String`
encoding.

A `String`'s representation in memory is more complex than the other datatypes:
while all other primitive datatypes occupy a fixed amount of space that can be
known ahead of time, `String`s whose size cannot be known at compile-time can be
created by concatenating two existing `String`s together [^StringConcat], or by
converting another datatype to a human-readable representation [^ToString].
Therefore `String`s are represented as a struct containing an 32-bit integer
representing the `String`s 'length' (the number of bytes occupied by the
`String`'s characters), and a pointer to the `String`'s UTF-8 encoded contents.
This pointer indirection allows each `String` to occupy the same amount of
memory on the stack, regardless of its contents. The runtime representation of
`String` is actually defined in C, not in LLVM IR, for ease of maintenance (see
@sec:impl:llvm:builtins):

```c
typedef int32_t Int;
typedef uint8_t Byte;
typedef struct {
  Int len;
  const Byte *const bytes;
} String;
```

The contents of each `String` is allocated on the heap, via the `malloc` library
function provided by C, unless the `String` value is a literal, in which case we
can apply a minor optimisation: since the contents of `String` literals are
known at compile-time, we can store the contents as a constant global array of
bytes, and then store a pointer to the global variable in the `bytes` field.
When converting to machine-code, LLVM will place these global arrays in a
section of the executable for global, readonly data (such as the `.rodata`
section in ELF executables). As a further optimiastion, we *deduplicate* string
literals: during codegen we maintain a `HashMap<String, PointerValue>`{.rust} mapping
each string literal contents to a global pointer. Thus the following program:

```rust
fn main() {
    let s1 = "hello" + "world";
    let s2 = "goodbye" + "world";
}
```

will only generate 3 global byte arrays, instead of 4:

```
@String.lit = global [5 x i8] c"hello"
@String.lit.1 = global [5 x i8] c"world"
@String.lit.2 = global [7 x i8] c"goodbye"
```

This choice of representation differs from that used by C. In C, a string value
is simply a pointer to a single `char` in memory. Since `char` pointers do not
carry around their length, the *null-character* acts as a *sentinel value* to
mark the end of a string (for this reason, C-style strings are also known as
*null-terminated strings*). This choice of representation was chosen due to the
memory constraints of the 1970s: computer memories were measured in kilobytes
and an extra integer per string value was considered an un-affordable luxury.
This memory-saving trick has a number of disadvantages compared to storing the
length alongside the contents-pointer:

* **Time complexity**: Calculating the length of a null-terminated string takes
  $O(n)$ time (ie time proportional to the length of the string): the string
  must be scanned left to right, starting at the first character, until a null
  character is found. By contrast, storing the string's length alongside its
  contents-pointer allows the length to be simply looked-up in $O(1)$ time (ie
  constant time) instead of calculated. A little extra book-keeping is required to
  update the length field after each operation that modifies or creates a new
  string, but this is usually simple.
* **Flexibility**: Null-terminated strings are unable to represent strings
  containing a null-character, since a null-character by definition marks the
  end of the null-terminated string. Attempts to insert a null-character into
  the middle of a null-terminated string will simply truncate the string to the 
  first occurrence of a null-character [^NullTruncated]. However, the null-
  character is a Unicode character in its own right ($U+0000$), and a string
  representation that cannot contain null-characters cannot faithfully represent
  every possible Unicode string.
 **Safety**: If the terminating null-character is omitted, attempts to
  calculate the string's length will blindly continue searching past the end of
  the string and either return an overestimate of the string's length (if a null
  character belonging to a nearby object in memory is found), or else cause a
  memory protection fault if the search crosses over into privileged or
  un-mapped memory. Since a primary aim of Walrus is that it should be
  impossible for normal code to produce undefined behaviour or violate memory
  safety, this makes null-terminated strings an unacceptable representation.

[^StringConcat]: See @sec:reference:operators
[^ToString]: See @sec:reference:builtin-functions for a list of functions that convert
builtin datatypes to their string representations.
[^NullTruncated]: For example, the C code `printf("Hello\0world!\n")` will
output `Hello` to the terminal.

#### Variables and mutation
Local variables introduced by let-statements, function/lambda arguments or
pattern matching, are represented as stack-allocated memory. LLVM provides a
special purpose instruction for allocating data on the stack: `alloca` allocates
a region of memory on the stack, which wil automatically be popped off the stack
when the current function returns. Reading from a variable is done with the
`load` instruction; initializing or mutating the variable is then achieved by
the `store` instruction:

```rust
let mut x = 5;
x = x + 1;
```

becomes
```
%x.alloca = alloca i32, align 4
store i32 5, i32* %x.alloca, align 4
%x = load i32, i32* %x.alloca, align 4
%Int.add = add i32 %x, 1
store i32 %Int.add, i32* %x.alloca, align 4
```

The reader may be concerned that storing all local variables on the stack, even
when they do not need to be (if they are never mutated) will lead to variables
being stored on the stack when they could be stored in machine registers.
However, this is beauty of the LLVM framework: we can generate fairly naive LLVM
IR, and rely on the LLVM optimizer to do the hard work of register allocation
for us.

#### Functions and closures
##### Toplevel functions
Top-level functions map very simply onto LLVM IR functions. We simply declare a
function with the correct type, and then generate the body.

```rust
fn add(x: Int, y: Int) -> Int {
    x + y
}
```
becomes

```
define i32 @add(i32 %add.params.0, i32 %add.params.1) {
add.entry:
  %x.alloca = alloca i32, align 4
  store i32 %add.params.0, i32* %x.alloca, align 4
  %y.alloca = alloca i32, align 4
  store i32 %add.params.1, i32* %y.alloca, align 4
  %x = load i32, i32* %x.alloca, align 4
  %y = load i32, i32* %y.alloca, align 4
  %Int.add = add i32 %x, %y
  ret i32 %Int.add
}
```

Note that we immediatly allocate stack space for each parameter passed in,
because function parameters can be mutated just like let-bound variables, if
they have been marked with the `mut` keyword. As before, we rely on the LLVM
optimizer to alleviate any performance loss due to our naive codegen strategy.

##### Builtin functions {#sec:impl:llvm:builtins}
We could have implemented Walrus' library of builtin functions (see
@sec:reference:builtins) using handwritten LLVM IR appended to the output LLVM
IR of every program. However, writing complex functions in LLVM IR by hand is
tedious and error prone. Instead, we implement our builtins in a single C file
of around 125 lines, and then statically both the C builtins and the LLVM IR of
the user's program together into a single executable using Clang. We would like
to investigate writing our builtins in Rust in the future, however this would
take some effort to implement as Rust has no stable ABI and a significantly more
complex build process than C.

##### Closures
Closures are significantly more complex to codegen. Since a closure can capture
variables from its environment, we need to include the captured values in
whatever runtime representation we select for closures. We chose to implement
closures using a method known as *closure-conversion*. The body of each closure
is represented as a top-level function, and closure values become a pair of a
pointer to the closure's function and a pointer to the closure's environment.
The closure's environment is allocated on the heap, via `malloc`, as the
environemnt can *escape* from the current stack-frame if the closure is returned
from a function - therefore if it were allocated on the stack, it would be
deallocated before the function returns. When calling a closure, the environment
pointer is passed to the top-level function, which then extracts the captured
values from the environment.

```rust
fn main() -> Int {
    let k = 5;
    let f = () => k;
    f()
}
```

becomes
```
define i32 @main() {
main.entry:
  %k.alloca = alloca i32, align 4
  store i32 5, i32* %k.alloca, align 4
  %closure.alloca = alloca { i32 (i8*)*, i8* }, align 8
  %closure.code = getelementptr inbounds { i32 (i8*)*, i8* }, { i32 (i8*)*, i8* }* %closure.alloca, i32 0, i32 0
  store i32 (i8*)* @lambda, i32 (i8*)** %closure.code, align 8
  %closure.env = getelementptr inbounds { i32 (i8*)*, i8* }, { i32 (i8*)*, i8* }* %closure.alloca, i32 0, i32 1
  %malloccall = tail call i8* @malloc(i32 0)
  %env.malloc = bitcast i8* %malloccall to {}*
  %env = bitcast {}* %env.malloc to i8*
  store i8* %env, i8** %closure.env, align 8
  %closure = load { i32 (i8*)*, i8* }, { i32 (i8*)*, i8* }* %closure.alloca, align 8
  %f.alloca = alloca { i32 (i8*)*, i8* }, align 8
  store { i32 (i8*)*, i8* } %closure, { i32 (i8*)*, i8* }* %f.alloca, align 8
  %f = load { i32 (i8*)*, i8* }, { i32 (i8*)*, i8* }* %f.alloca, align 8
  %closure.code1 = extractvalue { i32 (i8*)*, i8* } %f, 0
  %closure.env2 = extractvalue { i32 (i8*)*, i8* } %f, 1
  %lambda.call = call i32 %closure.code1(i8* %closure.env2)
  ret i32 %lambda.call
}

define i32 @lambda(i8* %env_ptr) {
lambda.entry:
  %env_ptr1 = bitcast i8* %env_ptr to {i32}*
  %env = load {i32}, {i32}* %env_ptr1, align 1
  %k = extractvalue {i32} %env, 0
  ret i32 %k
}
```

##### Wrapping toplevel and builtin functions
Since we want to be able to treat toplevel functions, builtin functions and
lambda expressions interchangably as first class values, function values must
have the same in memory-representation. Therefore toplevel and builtin functions
are wrapped in a closure with an empty environment, represented by the null
pointer. It is safe to use the null pointer, since the top-level/builtin
function will ignore the extra argument on the stack and never attempt to
dereference it.

```rust
fn main() -> _ { 
    let f = get_five;
    f()
}

fn get_five() -> _ {5}
```
becomes

```
define i32 @main() {
main.entry:
  %f.alloca = alloca { i32 (i8*)*, i8* }, align 8
  store { i32 (i8*)*, i8* } { i32 (i8*)* bitcast (i32 ()* @get_five to i32 (i8*)*), i8* null }, { i32 (i8*)*, i8* }* %f.alloca, align 8
  %f = load { i32 (i8*)*, i8* }, { i32 (i8*)*, i8* }* %f.alloca, align 8
  %closure.code = extractvalue { i32 (i8*)*, i8* } %f, 0
  %closure.env = extractvalue { i32 (i8*)*, i8* } %f, 1
  %lambda.call = call i32 %closure.code(i8* %closure.env)
  ret i32 %lambda.call
}

define i32 @get_five() {
get_five.entry:
  ret i32 5
}
```

Because it would be excessively wasteful (and make the resulting LLVM IR much
harder to understand when trying to debug the codegen pass) to wrap every
toplevel or builtin function in an empty closure before immediatly unwrapping
the closure to call it, we apply another optimisation: calls to variables, where
the variable is known to refer to a toplevel or builtin function, skip the
unneccesary closure wrapping and unwrapping, and just call the function
directly:

```rust
fn main() -> _ { 
    get_five()
}

fn get_five() -> _ {5}
```

becomes
```
define i32 @main() {
main.entry:
    %get_five.call = call i32 @get_five()
    ret i32 %get_five.call
}

define i32 @get_five() {
get_five.entry:
  ret i32 5
}
```

#### Control flow 

##### If expressions
Branching in LLVM IR is achieved by means of the `br` instruction, which either
selects between two basic-blocks to jump to based on the value of an `i1`, or
jumps unconditionally to a single basic block, depending on the syntax used.
Note that LLVM conditional branches must specify a branch for both the true and
the false cases - control does not "fall though" to the next basic block, as it
does in real assembly languages. To get the value of the branch taken, we use
the `phi` instruction, which selects between two values according to the
basic-block that control flow has arrived from.

```rust
fn main() -> _ {
    min(5, 10)
}

fn min(x: Int, y: Int) -> Int {
    if x < y { x } else { y }
}
```

becomes
```
define i32 @main() {
main.entry:
  %min.call = call i32 @min(i32 5, i32 10)
  ret i32 %min.call
}

define i32 @min(i32 %min.params.0, i32 %min.params.1) {
min.entry:
  %x.alloca = alloca i32, align 4
  store i32 %min.params.0, i32* %x.alloca, align 4
  %y.alloca = alloca i32, align 4
  store i32 %min.params.1, i32* %y.alloca, align 4
  %x = load i32, i32* %x.alloca, align 4
  %y = load i32, i32* %y.alloca, align 4
  %Int.less = icmp slt i32 %x, %y
  br i1 %Int.less, label %if.then, label %if.else

if.then:                                          ; preds = %min.entry
  %x1 = load i32, i32* %x.alloca, align 4
  br label %if.end

if.else:                                          ; preds = %min.entry
  %y2 = load i32, i32* %y.alloca, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %if.merge = phi i32 [ %x1, %if.then ], [ %y2, %if.else ]
  ret i32 %if.merge
}
```

When generating code for an if-expression without an else-branch, we simply
discard the result of the if branch and return the unit tuple:

```rust
fn main() {
    inspect(50);
}

fn inspect(x: Int) {
    if x == 42 {
        print("This number is special");
    }
}
```

becomes
```
%String = type { i32, i8* }

@String.lit = global [22 x i8] c"This number is special"

define {} @main() {
main.entry:
  %inspect.call = call {} @inspect(i32 50)
  ret {} zeroinitializer
}

define {} @inspect(i32 %inspect.params.0) {
inspect.entry:
  %x.alloca = alloca i32, align 4
  store i32 %inspect.params.0, i32* %x.alloca, align 4
  %x = load i32, i32* %x.alloca, align 4
  %Int.eq = icmp eq i32 %x, 42
  br i1 %Int.eq, label %if.then, label %if.else

if.then:                                          ; preds = %inspect.entry
  %print.call = call {} @builtin_print(%String { i32 22, i8* getelementptr inbounds ([22 x i8], [22 x i8]* @String.lit, i32 0, i32 0) })
  br label %if.end

if.else:                                          ; preds = %inspect.entry
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret {} zeroinitializer
}

declare {} @builtin_print(%String)
```

##### Loop expressions
TODO

#### Aggregate datatypes
##### Tuples
Code-generation of tuple-values is simple. Tuple values consist merely of the
values of thier elements stored one after another in contigious memory (and it
follows from this that 0-tuples occupy no memory at runtime). Since LLVM IR
includes anonymous struct types, we don't even need to declare a struct type
before constructing one. We simply construct an anonymous struct with the
correct fields in the correct order. Since LLVM doesnt allow constructing a
struct in one go (unless all the fields are constant expressions, which will not
be true in the general case), we have to stack allocate the struct, and then
initialize each field individually:

```rust
fn main() -> _ {
        (3.0, false, 1)
}
```

becomes
```
define { float, i1, i32 } @main() {
main.entry:
  %tuple.alloca = alloca { float, i1, i32 }, align 8
  %tuple.0.gep = getelementptr inbounds { float, i1, i32 }, { float, i1, i32 }* %tuple.alloca, i32 0, i32 0
  store float 3.000000e+00, float* %tuple.0.gep, align 4
  %tuple.1.gep = getelementptr inbounds { float, i1, i32 }, { float, i1, i32 }* %tuple.alloca, i32 0, i32 1
  store i1 false, i1* %tuple.1.gep, align 1
  %tuple.2.gep = getelementptr inbounds { float, i1, i32 }, { float, i1, i32 }* %tuple.alloca, i32 0, i32 2
  store i32 1, i32* %tuple.2.gep, align 4
  %tuple = load { float, i1, i32 }, { float, i1, i32 }* %tuple.alloca, align 4
  ret { float, i1, i32 } %tuple
}
```

##### Structs
Code-generation of struct values is nearly identical to that of tuple values,
since structs are simply tuples with named fields. The only distinction is that
we generate a distinct, named type for each struct type to allow for
cyclic types (see @sec:impl:llvm:cyclic-types):

```rust
struct S {
    x: Float,
    y: Bool,
    z: Int,
}

fn main() -> _ {
        S {x: 3.0, y: false, z: 1}
}
```

becomes
```
%S = type { float, i1, i32 }

define %S @main() {
main.entry:
  %S.alloca = alloca %S, align 8
  %S.x.gep = getelementptr inbounds %S, %S* %S.alloca, i32 0, i32 0
  store float 3.000000e+00, float* %S.x.gep, align 4
  %S.y.gep = getelementptr inbounds %S, %S* %S.alloca, i32 0, i32 1
  store i1 false, i1* %S.y.gep, align 1
  %S.z.gep = getelementptr inbounds %S, %S* %S.alloca, i32 0, i32 2
  store i32 1, i32* %S.z.gep, align 4
  %S = load %S, %S* %S.alloca, align 4
  ret %S %S
}
```

##### Enums
##### Cyclic types

#### Pattern matching

## Command-line interface