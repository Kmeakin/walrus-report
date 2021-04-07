---
monofont: 'Fira Mono'
---

# Reference {#sec:reference}

## Primitive Datatypes
Walrus has 5 primitive datatypes (`Bool`, `Int`, `Float`, `Char`, `String`), with
corresponding syntax for creating literal values.

### `Bool`s {#sec:reference:bools}
The `Bool` datatype represents the logical values of Boolean Algebra: `true` and
`false`. Since there are only 2 possible values of this datatype, each `Bool`
value occupies one byte of memory.

### `Int`s {#sec:reference:ints}
The `Int` datatype represents signed 32-bit integers: that is, integers between
$-2^{-31}$ ($-2,147,483,648$) and $2^{31}-1$  ($2,147,483,657$) inclusive. 
`Int`s are stored in memory as twos-complement's integers, and occupy 4 bytes each.

`Int` literals may be given in either decimal, binary or hexadecimal notation.
Underscores may be used to enhance the readability of long literals. Note that
sign prefixes (`+` or `-`) are *not* part of `Int` literals, but are unary
operators. Hence the code `-123` is actually lexed and parsed as a unary
operator  followed by a decimal integer literal.

```rust
0b101         // Binary
123_345_789   // Decimal
0x123_abc_789 // Hexadecimal
```
Walrus currently only has one integer type. This is in contrast to most other
strongly typed languages, which have different types for integers of different
sign and bit-width [^ExtraIntTypes]. Extra integral types could be added
to Walrus with little effort in future versions.

[^ExtraIntTypes]: See the `char`, `short`, `int`, `long`, hierarchy and
`signed`/ `unsigned` modifiers in C, or the `i8`/`u8` up-to `i128`/`u128` types
in Rust

### `Float`s {#sec:reference:floats}
The `Float` datatype represents (approximations of) real numbers: the binary32
format specified in IEEE-754-2008. This allows representing rational numbers
between $-3.40282347 \times 10^{38}$ and $3.40282347 \times 10^{38}$, as well as
positive and negative zero, positive and negative infinity, and various NaN
values. `Float`s are stored in memory according to the binary32 format, and
occupy 4 bytes of memory.

`Float` literals are given in decimal notation, with a decimal point separating
the integral and fractional parts. Scientific notation, such as `1.0e6` for one
million, is not currently supported. As with `Int` literals, sign prefixes are
parsed as separate unary operators, not as part of the `Float` literal. 

```rust
1_000_000.05
```

There is currently only one floating-point type: Walrus does not yet have a type
for binary64 floats [^ExtraFloatTypes].

[^ExtraFloatTypes]: See the `double` or `f64`  types in C and Rust, respectively.

### `Char`s {#sec:reference:chars}
The `Char` datatype represents single characters of textual data. However,
unlike the `char` datatype in C, which may represent a 7-bit ASCII character, a
16-bit UTF-16 code-unit, or a 8-bit UTF-8 code-unit depending on the platform,
Walrus' `Char`s are always capable of representing any Unicode character, and
have the same representation on every platform.

Each single `Char` is a 'Unicode Scalar Value': that is any 'Unicode Code Point'
except for high and low surrogates, which are only needed in UTF-8 encodings.
In terms of memory representation, this corresponds to any integer value between
$0$ and $D7FF_{16}$ or $E000_{16}$ and $10FFFF_{16}$, inclusive. A consequence
of this representation is that every `Char` value occupies 4 bytes in memory,
even if it is an ASCII character that could fit within 1 byte.

`Char` literals are given by enclosing the literal character within
single-quotes, or by specifying the exact Unicode Scalar Value if a difficult 
to type character is needed. A few commonly used non-graphical characters also
have their own special shorthand syntax, inherited from C:

|Shorthand|Description      |Unicode Scalar Value
|---------|-----------------|--------------------
|`'\n'`   | newline         | `U+000A` 
|`'\r'`   | carriage return | `U+000D` 
|`'\t'`   | horizontal tab  | `U+0009` 
|`'\0'`   | null character  | `U+0000` 
|`'\''`   | single quote    | `U+0027` 
|`'\"'`   | double quote    | `U+0022` 
|`'\\'`   | backslash       | `U+005C` 

```rust
'a'        // The first letter of the Latin alphabet
'λ'        // The eleventh letter of the Greek alphabet
'\u{03BB}' // The same Greek letter
'\n'       // A newline
```

### `String`s {#sec:reference:strings}
The `String` datatype represents textual data. Unlike `Char`s, which represent a
single character, `String`s may represent several characters (or none). As with
`Char`s, `String`s may represent any possible sequence of Unicode characters.

When storing a series of Unicode characters, there are 3 potential schemes for
translating a series of 32-bit Unicode Code Points into a series of 8-bit bytes,
depending on the size of each Code Unit. UTF-32 encodes each Code Point as a single
32-bit Code Unit, even if it could fit in a single byte. UTF-16 encodes each
Code Point as 1 or more 16-bit Code Units, and suffers from the same problem as
UTF-16, in that ASCII characters that could be optimally represented as a single
byte occupy 2 bytes. Only UTF-8 does not have this overhead: ASCII characters
are stored exactly as they would be in a legacy ASCII string. Only Code Points
greater than $FF_{16}$ will be encoded as multiple 8-bit Code Units. For this
reason, Walrus uses UTF-8 for its `String` encoding.

A `String`'s representation in memory is more complex than the other datatypes:
while all other primitive datatypes occupy a fixed amount of space that can be
known ahead of time, `String`s whose size cannot be known at compile-time can be
created by concatenating two existing `String`s together [^StringConcat], or by converting
another datatype to a human-readable representation [^ToString]. Therefore
`String`s are represented as a pair of a 32-bit integer representing the `String`s
'length' (the number of bytes occupied by the `String`'s characters), and a
pointer to the `String`'s UTF-8 encoded contents. This pointer indirection
allows each `String` to occupy the same amount of memory on the stack,
regardless of its contents.

This choice of representation differs from that used by C. In C, a string value
is simple a pointer to a single `char` in memory. Since string values do not
carry around their length, the *null-character* acts as a *sentinel value* to
mark the end of a string. (for this reason, C-style strings are also known as
*null-terminated strings*) This choice of representation was chosen due to the
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
* **Safety**: If the terminating null-character is omitted, attempts to
  calculate the string's length will blindly continue searching past the end of
  the string and either return an overestimate of the string's length (if a null
  character belonging to a nearby object in memory is found), or else cause a
  memory protection fault if the search crosses over into privileged or
  un-mapped memory. Since a primary aim of Walrus is that it should be
  impossible for normal code to produce undefined behaviour or violate memory
  safety, this makes null-terminated strings an unacceptable representation.

String literals are given by enclosing the text within double-quotes. As with
`Char` literals, the contents may be entered verbatim, by giving the Unicode
Code Point, or by using the backslash shorthand:

```
"Hello, world!\n"          // A timeless greeting
"Hello,\u{20}world!\u{0A}" // The same greeting, with Unicode Code Points
"Γειά σου Κόσμε!\n"        // The same greeing, in Greek
```

[^StringConcat]: See @sec:reference:operators
[^ToString]: See @sec:reference:builtin-functions for a list of functions that convert
builtin datatypes to their string representations.
[^NullTruncated]: For example, the C code `printf("Hello\0world!\n")` will
output `Hello` to the terminal.

## Identifiers {#sec:reference:identifiers}
Identifiers are used in Walrus to signify any entity that requires a name: local
variables, functions, structs and enums, and fields. Identifiers may consist of
any sequence of alphabetic characters, digits, and underscores, as long as the
resulting identifier would not be a single underscore or start with a digit.

```rust
abcXYZ
λ           // Unicode letters are allowed
hello_world // Identifiers can include underscores
_hello      // or start with underscores
_           // but a single underscore is not an identifier

the_number_123 // Identifiers can include digits
123abc         // but they cannot start with digits
```

## Let bindings {#sec:reference:let-bindings}
Local variables are introduced by *let-statements*:

```rust
let x = 5;
```

Optional type-annotations may be supplied, but most of the time Walrus' type
inference is sophisticated enough to infer the type of the variable without
needing an explicit annotation [^LetTypes].

```rust
let x: Int = 5;
```

Once defined, a variable is said to be *in-scope*  and can be referred to in
subsequent expressions (it is an error to attempt to refer to a local variable
before it has been defined).

```rust
let x = 5;
let y = 6;
let z = x + y;
```

Unlike in C, it is not an error to introduce a new variable with the same name
as an existing in-scope variable: instead, the old binding is said to be
*shadowed* - it is no longer accessible:
```rust
let x = 5;
let x = x + 1; // x is now 6, old variable is inaccessible
```

All local variables are *immutable* by default. To mutate a variable, mutability
must be explicitly requested using the `mut` keyword: 
```rust
let mut x = 5;
x = x + 1;
```

Making immutability the default option nudges the user towards writing their
code in a functional style where new variables are produced instead of updating
existing variables. However, the option of mutability is still available if an
algorithm cannot easily be expressed with immutability.

Local variables must be declared and initialized in the same let-statement. It
is not possible to declare a variable without initializing it and then initialize
it by mutating it later. For a rationale for this design, consider the following
C code:
```c
int x;
printf("The value of x is %d\n", x);
```
This code reads from the memory region denoted by `x`, even though that memory
is uninitialized. In other words, it produces undefined behaviour. Walrus removes
the possibility of reading from uninitialized variables by making a let-statement
without an initializing expression a syntax error.

Rust *does* manage to allow separate definition and initialization of variables,
without undefined behaviour creeping into user programs, by performing a
data-flow analysis to check that each variable has been initialized in every
possible path of control flow before it is first read from. This feature was
left out of Walrus for lack of time.

[^LetTypes]: See @sec:reference:types for more information about types and type-inference.

## Operators {#sec:reference:operators}
Walrus provides a set of arithmetical and logical operators (both *prefix* and
*infix*) for performing operations that are too primitive to be implemented by
users in normal Walrus code:

|Operator         | Description
|-----------------|----------------------------
|prefix `-`       | Negates `Int`s and `Float`s
|prefix `+`       | Identity operator on `Int`s and `Float`s
|prefix `!`       | Negates `Bool`s
|infix `&&`, `||` | Short-circuiting $\land$ and $\lor$ on `Bool`s
|infix `+`        | Adds `Int`s and `Float`s, concatenates `String`s
|infix `-`        | Subtracts `Int`s and `Float`s
|infix `*`        | Multiplies `Int`s and `Float`s
|infix `/`        | Divides `Int`s and `Float`s
|infix `=`        | Mutates local variables and struct fields
|infix `==`, `!=`, `<`, `<=`, `>`, `>=` | Compares primitive types

Operators have set rules of *precedence* and *associativity* which determine the
final syntax tree built by the parser. This allows the user to write 
`1 + 2 * 3 - 4`{.rust} in standard mathematical notation, instead of a
hypothetical `sub(add(1, mul(2, 3)), 4)`{.rust} using only functions:

| Operator             | Precedence | Associativity
|----------------------|------------|---------------
| prefix `-`, `+`, `!` | Highest    | Left
| infix `*`, `/`       |            | Left
| infix `+`, `-`       |            | Left
| infix `==`, `!=`, `<`, `<=`, `>`, `>=` |  | Left
| infix `&&`           |            | Left
| infix `||`           |            | Left
| infix `=`            | Lowest     | Right

As in standard mathematical notation, parentheses bind tighter than any
operators, and so can be used to override the normal operator precedences:
`(1 + 2) * (3 - 4)`{.rust}

Unlike languages such as Haskell or Ocaml, the set of operators in Walrus is
fixed: new operators cannot be defined by the user. This simplifies parsing, but
can make expressions which could otherwise be expressed in specialised notation
a little more cumbersome to write.

Walrus operators also cannot be treated as first-class values as they can be in
Haskell or Ocaml, where an operator can be treated as a variable by enclosing it
in parentheses: `(+)`{.haskell} and passed to other functions: `foldr (+) 0
xs`{.haskell}. The set of types to which each operator can be applied is also
fixed: the user cannot provide their own implementation of an operator for other
types. These two limitations are due to a current shortcoming in Walrus' type system, which will be explained in depth in @sec:reference:types.

## Functions and Closures {#sec:reference:functions}
Functions are the primary unit of abstraction in Walrus, allowing complex
programs to be split into smaller independent parts:
```rust
fn hello() -> String {
    "hello"
}

fn world() -> _ {
    "world"
}

fn main() {
    print(hello() + world())
}
```

Functions automatically return the value of the last expression in their body
(or the unit value, `()`, if the body is empty or consists only of statements).
No explicit `return` is necessary as in C ^[though explicit returns can still be
used, see @sec:reference:control-flow]. The return type of a function can be
specified on the right-hand-side of the `->` (as in `hello`), or left blank to let
the Walrus compiler infer the correct type (as in `world`). If no return type is
given, the function is assumed to return the unit type, `()`, (as in `main`).

### Function parameters
As well as returning values, functions can accept input *parameters* and operate
on them:
```rust
fn square(x: Int) -> Int {
    x * x
}

fn main() {
    print("10 squared is " + int_to_string(square(10)))
}
```

As function parameters are local variables, they can be mutated just like
variables introduced by let-statements:
```rust
fn mutate(mut x: Int) {
    x = x + 1;
    print(int_to_string(x) + " ")
}

fn main() {
    let x = 5;
    print(int_to_string(x) + " ")
    mutate(x);
    print(int_to_string(x))
}
```
Note however that this program will print `5 6 5`, not `5 6 6` as some readers
may have expected. This is because arguments to functions are always passed 
*by value* in Walrus, not *by reference* as objects (but not primitive types) are in
Java. In other words, each function receives a new, independent copy of the
arguments passed in. It may help to think of the `mutate` function as being
equivalent to 
```rust
fn mutate(x: Int) {
    let mut x = x;
    x = x + 1;
    print(int_to_string(x) + " ")
}
```
which should make it apparent that any mutations done on `mutate`'s parameters
will be local to the body of `mutate`.

In C, which is also a call by value language, it *is* possible to write a version
of `mutate` that will make its mutation visible to the caller:
```c
void mutate(int* x) {
    *x = *x + 1;
    printf("%d ", *x);
}

void main() {
    int x = 5;
    printf("%d ", x);
    mutate(&x);
    printf("%d", x);
}
```
This is because `mutate` now receives a pointer to the memory location occupied
by `x`, rather than a copy of the value in `x`.

An equivalent function in Walrus is not yet possible, as Walrus currently does
not have references.

### Function scoping
Unlike local variables, functions are *globally-scoped*: a function need not be
defined before it is referred to (as long as it is defined *somewhere* in the
file). There is no requirement to separately *declare* and *define* a pair of
mutually-recursive functions as in C:
```c
// This declaration is required, as otherwise is_odd will not 
// be in the scope of is_even
bool is_odd(unsigned int x); 

bool is_even(unsigned int x) {
    return x == 0 || is_odd(x - 1)
}

bool is_odd(unsigned int x) {
    return x != 0 || is_even(x - 1)
}
```

The equivalent [^NotQuiteEquivalent] pair of functions can be written in Walrus without needing to
repeat `is_odd`'s signature:
```rust
fn is_even(x: Int) -> Bool {
    x == 0 || is_odd(x - 1)
}

fn is_odd(x: Int) -> Bool {
    x != 0 || is_even(x - 1)
}
```

Since functions exist in the global scope, they cannot be shadowed: it is an
error to define two functions with the same name.

[^NotQuiteEquivalent]: The astute reader will notice that these functions
are not *exactly* equivalent to their C counterparts, as they will recur
repeatedly until causing a stack overflow if passed a value less than `0`.
Unfortunately, this is the best implementation that can be done until unsigned integers are added to Walrus.

### First class functions
Walrus functions are first class values: they can not only be called, but also
be passed around and stored in variables:

```rust
fn apply(f: (Int) -> Int, x: Int) -> Int {
    f(x)
}

fn square(x: Int) -> Int {
    x * x
}

fn main() {
    let f = square;
    print("10 squared is " + apply(f, 10))
}
```

### Lambdas
As well as global, named functions, Walrus allows the creation of local,
*anonymous* functions (also sometimes called *lambda abstractions* or simply
*lambdas*):

```rust
fn quadratic(a: Int, b: Int, c: Int) -> (Int, Int, Int) -> Int {
    (x) => a * x * x + b * x + c
}

fn main() {
    let f = quadratic(10, 5, -2);
    print("f(2) = " + int_to_string(f(2)));
}
```

Lambda abstractions are also able to *close over their envionment*: if the body
of a lambda abstraction refers to a variable that is defined in its enclosing
scope (its *environment*), rather than defined in its parameter list, it is said
to *capture* that variable: the lambda value now carries around an independent
copy of the captured variable, which will then be read from when the lambda
value is subsequently called. The resulting combination of function code and
captured variables is called a *closure*:

```rust
fn constantly(k: Int) -> (Int) -> Int {
    (_) => k
}

fn main() {
    let always_5 = constantly(5);
    print(int_to_string(always_5(1)));
    print(int_to_string(always_5(2)));
    print(int_to_string(always_5(3)));
}
```

## Builtin Functions {#sec:reference:builtin-functions}
Walrus has a small collection of built-in functions provided by the compiler:

|Name             |Type                 |Description                      |
|-----------------|---------------------|---------------------------------|
|`print`          | `(String) -> ()`    | Print to standard-output        |
|`print_error`    | `(String) -> ()`    | Print to standard-error         |
|`string_length`  | `(String) -> Int`   | Get the length of a `String`    |
|`bool_to_string` | `(Bool) -> String`  | Convert a `Bool` to a `String`  |
|`int_to_string`  | `(Int) -> String`   | Convert an `Int` to a `String`  |
|`float_to_string`| `(Float) -> String` | Convert a `Float` to a `String` |
|`char_to_string` | `(Char) -> String`  | Convert a `Char` to a `String`  |
|`exit`           | `(Int) -> String`   | Immediately exit the program, returning the status to the shell |

These functions are implicitly in global scope, even though they are not defined
anywhere. Unlike user-defined functions, they *can* be shadowed.

## Control Flow {#sec:reference:control-flow}
### If {#sec:reference:if}
The *if-expression* allows selecting between alternative branches based on a
condition:
```rust
fn max(x: Int, y: Int) -> Int {
    if x > y {
        x
    } else {
        y
    }
}
```

If the `else` branch is omitted, the body is executed only for side effects, and
`()` is returned:
```rust
fn square(x: Int, verbose: Bool) {
    if verbose {
        print("squaring " + int_to_string(x))
    }
    x * x
}
```

If-expressions can be *chained* to perform multiple conditional checks, selecting
the first branch that evaluates to true:
```rust
fn sign(x: Int) -> String {
    if x > 0 {
        "positive"
    } else if x < 0 {
        "negative"
    } else {
        "zero"
    }
}
```

This function is equivalent to
```rust
fn sign(x: Int) -> String {
    if x > 0 {
        "positive"
    } else {
        if x < 0 {
            "negative"
        } else {
            "zero"
        }
    }
}
```

### Loops
The *loop-expression* allows repeating a block until a *break-expression* is evaluated:
```rust
fn countdown(mut x: Int) {
    loop {
        if x == 0 {
            break;
        } else {
            print(int_to_string(x) + "\n");
            x = x - 1;
        }
    }
}
```

A break-expression may optionally accept a value, which becomes the final
result of the enclosing loop-expression:
```rust
fn smallest_prime_factor(x: Int) -> Int {
    let mut q = 2;
    loop {
        if x % q == 0 {
            break q;
        }
        q = q + 1;
    }
}
```

As well as `break` to terminate early, loops may `continue` to skip the rest of
the loop body and start the next iteration early [^NoReadLine]:
```rust
fn login() -> Int {
    let secret = 42;
    let max_length = 20;
    let password = "password";

    loop {
        print("password: ");
        let line = read_line();
        if line == "" {
            print("Password cannot be empty\n");
            continue;
        }
        if string_length(line) > max_length {
            print("Password is too long\n");
            continue;
        }
        if line != password {
            print("Incorrect password\n");
            continue;
        }
        break secret;
    }
}
```

[^NoReadLine]: Assume for the sake of this example that a builtin function
`read_line: () -> String` exists

#### Nonterminating loops
A loop-expression with no `break` expression inside its body will never
terminate. This means it has no meaningful return type, not even the unit type,
`()`. Instead, the return type of an infinite loop is `Never`. The `Never` type
will be explained in @sec:reference:types.

### Early Returns

## Tuples {#sec:reference:tuples}
## Structs {#sec:reference:structs}
## Enums {#sec:reference:enums}
## Pattern Matching {#sec:reference:pattern-matching}
## Type Inference {#sec:reference:types}
