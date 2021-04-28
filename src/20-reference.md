# Reference {#sec:reference}

## Primitive Datatypes {#sec:reference:primitive-types}
Walrus has 5 primitive datatypes (`Bool`, `Int`, `Float`, `Char`, `String`), with
corresponding syntax for creating literal values.

### `Bool`s {#sec:reference:bools}
The `Bool` datatype represents the logical values of Boolean Algebra: `true` and
`false`. 

### `Int`s {#sec:reference:ints}
The `Int` datatype represents signed 32-bit integers: that is, integers between
$-2^{-31}$ ($-2,147,483,648$) and $2^{31}-1$  ($2,147,483,657$) inclusive. 

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
values. 

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

String literals are given by enclosing the text within double-quotes. As with
`Char` literals, the contents may be entered verbatim, by giving the Unicode
Code Point, or by using the backslash shorthand:

```
"Hello, world!\n"          // A timeless greeting
"Hello,\u{20}world!\u{0A}" // The same greeting, with Unicode Code Points
"Γειά σου Κόσμε!\n"        // The same greeing, in Greek
```

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

### Mutation
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

### Initalisation
Local variables must be declared and initialised in the same let-statement. It
is not possible to declare a variable without initialising it and then initialise
it by mutating it later. For a rationale for this design, consider the following
C code:
```c
int x;
printf("The value of x is %d\n", x);
```
This code reads from the memory region denoted by `x`, even though that memory
is uninitialised. In other words, it produces undefined behaviour. Walrus removes
the possibility of reading from uninitialised variables by making a let-statement
without an initialising expression a syntax error.

Rust *does* manage to allow separate definition and initialisation of variables,
without undefined behaviour creeping into user programs, by performing a
data-flow analysis to check that each variable has been initialised in every
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
operators, and so can be used to override the normal operator precedence:
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
types. These two limitations are due to a current shortcoming in Walrus' type
system, which will be explained in depth in @sec:reference:types.

## Lvalues {#sec:reference:lvalues}
Although the assignment operator, `=` can syntactically acccept an expression on
its left-hand side, semantically it only makes sense to mutate an expression
that refers to a location in memory: it would not make sense to attempt to
mutate a literal expression, or a temporary result of an intermediate
expression. Values that can be mutated are called *lvalues*, and all other
values are called *rvalues*, for *left-hand side values* and *right-hand side
values* respectively ^[This terminology is inherited from C. C++ extends the
classification of values by adding more exotic categories such as *glvalues*,
*prvalues* and *xvalues*. See
https://en.cppreference.com/w/cpp/language/value_category for more information]
Lvalues in Walrus are defined inductively as:

* A variable expression is an lvalue
* A parenthesised lvalue expression is an lvalue
* A field-expression, where the expression to the left of the `.` is an lvalue,
  is an lvalue

Intuitively, this means that only variables and struct fields can be mutated.

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

Lambda abstractions are also able to *close over their environment*: if the body
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

## Blocks {#sec:reference:blocks}
A block expression allows sequencing statements. In this respect they are the
same as *compound-statements* from C or Java, except that they evaluate to a
final value. A statement is either a let-statement, which was described earlier
in @sec:ref:variables, or an *expression-statement*, which is simply a normal
expression terminated by a semicolon - this has the effect of evaluating the
expression for its side-effects and discarding the return value. The return
value of a bock expression is the return value of its trailing expression, or
else `()` if no trailing expression is present. Block expressions also follow
the rules of *lexical-scoping*: each variable defined within a block expression
shadows and previously defined variables of the same name, and go out of scope
at the end of the innermost block expression in which they were defined:

```rust
fn main() {
    let x = {
        let y = 5;
        print("y is: " + int_to_string(y));
        y
    };
    print("x is: " + int_to_string(x));
    x
}
```

Note that if the expression in an expression-statement ends with a `}` (that is,
it is an if-expression, loop-expression, or block-expression), the trailing
semicolon can be discarded. Thus

```rust
fn is_zero(x: Int) -> bool {
    if x == 0 {
        print("x is indeed zero");
    }
    x == 0
}
```

is the same as

```rust
fn is_zero(x: Int) -> bool {
    if x == 0 {
        print("x is indeed zero");
    };
    x == 0
}
```

## Builtin Functions {#sec:reference:builtin-functions}
Walrus has a small collection of built-in functions provided by the compiler:

|Name             |Type                 |Description                      |
|-----------------|---------------------|---------------------------------|
|`read_line`      | `() -> String`      | Read a line from standard-input |
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

### Loops {
A loop-expression simply repeats its body until it encounters a `break`
expression:
```rust
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
            print_error("Password cannot be empty\n");
            continue;
        }
        if string_length(line) > max_length {
            print_error("Password is too long\n");
            continue;
        }
        if line != password {
            print_error("Incorrect password\n");
            continue;
        }
        break secret;
    }
}
```

#### Non-terminating loops
A loop-expression with no `break` expression inside its body will never
terminate. This means it has no meaningful return type, not even the unit type,
`()`. Instead, the return type of an infinite loop is `Never`. The `Never` type
will be explained in @sec:reference:types.

### Early Returns
Just as `break` allows programs to return from loops early, `return` allows
programs to return from functions early, without executing the rest of the
function body. Although Walrus' practice of automatically returning the value of
the last expression in a function body obviates most of the need for `return`,
it may still be useful in situations where a function cannot easily be
expressed with a single exit point.

TODO: example of early return

## Aggregate datatypes {#sec:reference:aggregates}
All datatypes we have dealt with so far have been so-called
*primitive datatypes*: the atoms from which other, more complex types can be
built. Walrus has 3 methods of building more complex *aggregate datatypes* from
combinations of primitive datatypes and other aggregate datatypes: *tuples*,
*structs* and *enums*.

### Tuples {#sec:reference:tuples}
A tuple is an ordered sequence of elements. Unlike other ordered collections,
such as lists or vectors, tuples are *heterogeneous*, meaning that each element
of the tuple can be distinct, and tuples of different *arity* (number of
elements) are considered to be distinct, incompatible types.

Tuples are produced by writing their elements in order, enclosed in parentheses.
Note that 1-tuples require a trailing comma in order to disambiguate them from a
parenthesised expression:
```rust
let unit: () = ();                  
let singleton: (Int,) = (1,);       
let not_a_tuple: Int = (1);
let pair: (Int, Bool) = (1, false);
let triple: (Int, Bool, String) = (1, false, "hello");
```

The individual elements of a tuple can be accessed either by *destructuring* the
tuple via pattern-matching (see @sec:reference:pattern-matching), or by
accessing the element as a field of the tuple:
```rust
let pair = (1, 2);
let (x1, y1) = pair;
let x2 = pair.0;
let y2 = pair.1;
```

Tuples are useful for when you need to group data together, without the full
ceremony of declaring a separate *struct* type to hold them. A common use case
for tuples is for returning multiple values from a function. 

Consider attempting to write a function that returns both the quotient of two
integers, and any remainder left over (for simplicity we will ignore the case
where the divisor is 0). In C, functions can only return 1 value (or `void` if
they return no values), so the implementer must either mutate a pointer passed
in by the caller, or declare a new struct which it returns:
```c
void quot_rem_a(int x, int y, int* quot, int* rem) {
    *quot = x / y;
    *rem = x % y;
}

typedef struct {
    int quot;
    int rem;
} quot_rem_t;

quot_rem_t quot_rem_b(int x, int y) {
    return (quot_rem_t){.quot = x / y, .rem = x % y};
}

void main() {
    int x = 5;
    int y = 2;
 
    int quot, rem;
    quot_rem_a(x, y, &quot, &rem);
    printf("%d divides %d %d times, with remainder %d\n", y, x, quot, rem);

    quot_rem_t quot_rem = quot_rem_b(x, y);
    printf("%d divides %d %d times, with remainder %d\n", y, x, 
            quot_rem.quot, quot_rem.rem);
}
```

By contrast, in Walrus, you can simulate multiple return values by returning a tuple:
```rust
fn quot_rem(x: Int, y: Int) -> (Int, Int) {
    (x / y, x % y)
}

fn main() {
    let x = 5;
    let y = 2;
    let (quot, rem) = quot_rem(x, y);
    print(int_to_string(y) + " divides " + int_to_string(x) + " " +
          int_to_string(quot) + " times, with remainder " + int_to_string(rem));
}
```

A 0-tuple is the canonical unit type in Walrus, and is used for expressions that
return no meaningful data, such as the assignment expression or the `print`
function. See @sec:reference:types:unit for more information.

### Structs {#sec:reference:structs}
Structs are similar to tuples, in that they are heterogeneous collections.
However, unlike tuples, struct fields are indexed by name rather than position:
```rust
struct Person {
    name: String,
    age: Int,
    weight: Float,
}
```

Once declared, values of a struct can be *constructed* by giving an initializer
value for each field in the struct:
```rust
let p = Person {
    name: "John Doe",
    weight: 100.0,
    age: 21,
};
```
The fields in the constructor needn't be initialised in the same order as they
are given in the struct declaration, but all fields must be initialised: a *
via pattern matching, or by accessing individual fields:
```rust
let Person{name, weight, age} = p;
let name2 = p.name;
let weight2 = p.weight;
let age2 = p.age;
```

#### Lack of constructors
Unlike C++ or Java classes, Walrus structs cannot have "constructor methods"
associated with them. The only way to create a struct value is to simply provide
the value of all the fields up front. This design choice was made because
constructors may leave a class in an inconsistent state if they `return` early
or throw an exception.

Consider a Java `Person` class with a constructor that calculates a Person's age
from their year of birth. This requires getting the current date via an
(imaginary) `getCurrentYear` function, which on rare occasions may throw an
exception for various reasons. If this exception is not caught, the constructor
will terminate early, resulting in a `Person` with an uninitialised `age` and `weight`:
```java
class Person {
    String name;
    int age;
    float weight;

    Person(String name, int birthYear, float weight) {
        this.name = name;
        int currentYear = getCurrentYear();
        this.age = currentYear - birtthYear;
        this.weight = weight;
    }
}
```

By contrast, the corresponding Walrus function will either successfully return a
fully initialised person, or else return an error which must be handled by the
caller ^[See @sec:reference:enums and @sec:reference:pattern-matching for a
description of the `enum` and `match` keywords]:
```rust
enum PersonResult {
    Ok{p: Person},
    Err{e: ClockError},
}

fn new_person(name: String, birth_year: Int, weight: Float) -> PersonResult {
    let current_year = match get_current_year() {
        YearResult::Ok{year} => year,
        YearResult::Err{err} => return PersonResult::Err{err},
    };
    PersonResult::Ok{p: Person{name, weight, age: current_year - birth_year}}
}
```

#### Nominal typing
Structs are also named and therefore *nominally-typed*: two structs declared with
different names have different types, even if they have exactly the same contents.
Nominal typing of structs allows the contents of an aggregate datatype to be
separated from the intended meaning of the type. For example, a coordinate in 3D
space, and a date in day-month-year format can both be represented as a `(Int,
Int, Int)` 3-tuple, but this would create an opportunity for two types with
different meanings to get confused:
```rust
fn print_event(date: (Int, Int, Int), position: (Int, Int, Int), description: String) {
    let (day, month, year) = date;
    let (x, y, z) = position;
    print(...)
}

fn main() {
    let date = (01, 01, 1970);
    let position = (0, 0, 0);
    let description = "something happened";
    print_event(date, position, description); // Order of arguments is incorrect, 
                                              // but no error is indicated
}
```

If instead structs were used, it would be impossible to accidentally pass the
arguments to `print_event`{.rust} in the wrong order:
```rust
struct Position {
    x: Int,
    y: Int,
    z: Int,
}

struct Date {
    day: Int,
    month: Int,
    year: Int,
}

fn print_event(date: Date, position: Position, description: String) {
    ...
}

fn main() {
    let date = (01, 01, 1970);
    let position = (0, 0, 0);
    let description = "something happened";
    print_event(position, date, description); // Type error

}
```

### Enums {#sec:reference:enums}
Despite their name, enums are much more powerful than enum types in C or Java^[A
more appropriate name would be *algebraic datatype*, as they are known in
functional programming. However, Walrus inherits the `enum` name from Rust,
which chose the name `enum` as it would be more familiar to C programmers].
Walrus' enums are capable of representing one of several different structs
(called *variants* when in the context of an enum) at once:
```rust
enum IntOrFloat {
    Int{x: Int},
    Float{y: Float},
}
```

Enum values are constructed similarly to struct values, by specifying an
initalizer for each field:
```rust
let int = IntOrFloat::Int{x: 5},
let float = IntOrFloat::Float{y: 5.0},
```

Unlike structs, the fields of an enum cannot be accessed simply by accessing the
individual fields, since which variant the enum occupies is only known at
runtime. Instead, the enum must be pattern-matched over ^[See
@sec:reference:pattern_matching for more information on pattern-matching]:

```rust
fn print_int_or_float(it: IntOrFloat) {
    match it {
        IntOrFloat::Int{x} => print("Its an Int: " + int_to_string(x)),
        IntOrFloat::Float{y} => print("Its a Float: " + float_to_string(y)),
    }
}
```

Traditional C-style `enum`s can be mimicked by creating a Walrus `enum` where each
variant has 0 fields:
```rust
enum Colour {
    Red{},
    Green{},
    Blue{},
}
```

Enums are similar to *unions* in C, which can also be one of several types:
```c
typedef union {
    int x;
    float y;
} IntOrFloat;
```

However, C unions carry no information at runtime to indicate which variant they
occupy: accessing a variant of an enum simply reinterprets the contents of the
enum as a value of the intended type. It is up-to the programmer to ensure that
the correct variant is accessed at the correct time:
```c
typedef union {
    int x;
    float y;
} IntOrFloat;

void main() {
    IntOrFloat integer = (IntOrFloat){.x=-1};
    IntOrFloat floating = (IntOrFloat){.y=-1.0};

    printf("%d\n", integer.x); // prints "-1"
    printf("%f\n", integer.y); // prints "-nan"

    printf("%d\n", floating.x); // prints "-1082130432"
    printf("%f\n", floating.y); // prints "-1.000000"
}
```
In contrast, Walrus enums carry a *tag* indicating which variant they occupy at
runtime, which allows fields to be accessed safely via pattern matching. The
tag + fields representation is similar to that of the *tagged-union* design
pattern in C, except in C the burden is still on the programmer to check the tag
before accessing the fields:

```c
typedef enum {
    INT,
    FLOAT,
} IntOrFloatTag;

typedef struct {
    IntOrFloatTag tag;
    union {
        int x;
        float y;
    };
} IntOrFloat;

void print_int_or_float(IntOrFloat it) {
   switch (it.tag) {
       case INT:
        printf("its an Int: %d\n", it.x);
        break;
       case FLOAT:
        printf("its a Float: %f\n", it.y);
        break;
   }
}
```

#### Enum use cases
##### Eliminating null
Many languages have a concept of a `null` value to represent when a value is
missing or invalid. This often occurs in algorithms for searching and lookup.
Consider Java's `HashMap<K, V>` (`java.util.HashMap<K, V>` to be
precise), where `K` is the type of the key and `V` is the type of the value
being stored. Objects can be inserted into the map with the 
`void put(K key, V value)`{.java} method and retrieved with the 
`V get(Object key)` method.
In the case where `get` is called with a key that is not present, `get` must
return an object of type `V` which is in fact not a valid `V` at all, but a
dummy value to indicate that no entry was found. This is what `null` is for.

The inclusion of null-references is considered by many today to be a mistake:

> I call it my billion-dollar mistake. It was the invention of the null
> reference in 1965. At that time, I was designing the first comprehensive type
> system for references in an object oriented language (ALGOL W). My goal was to
> ensure that all use of references should be absolutely safe, with checking
> performed automatically by the compiler. But I couldn't resist the temptation
> to put in a null reference, simply because it was so easy to implement. This
> has led to innumerable errors, vulnerabilities, and system crashes, which have
> probably caused a billion dollars of pain and damage in the last forty years.
- Tony Hoare

Here are just some of the symptoms of those billion dollars of pain and damage:

* **It is too permissive**: The type `T` implicitly includes the `null` value,
  even if there is no meaningful interpretation of `null` in a particular
  context. Countless methods in the Java standard library accept reference
  types, such as `String`, only to throw `NullPointerException` if the reference
  type passed in is `null`. This means that their API is too permissive, because
  invalid arguments can be ruled out only at runtime, not at compile-time via the
  type system. 
* **It confuses different cases**: methods like `HashMap.get`{.java} return
  `null` when no valid output exists. However, in some situations, `null` is
  itself a valid value: consider a `HashMap<String, Degree>`{.java}, which maps
  the name of students and alumni of university name to their degree if they
  have one, or `null` if they have not yet graduated. In this case, receiving a
  `null` value from `get` could mean one of two things: that the person looked
  up is not a current or former student at the university, or that the person is
  a current student who has not yet graduated. To distinguish between these two
  cases requires a separate method, such as `HashMap.containsKey`.
* **It is not general enough**: `null` is only valid when the value in question
  can be represented as a pointer: in Java, instances of classes are represented
  as pointers to the heap, and so can be `null`. But Java's "primitive types"
  (`int`, `float`, `boolean`, etc) are stored inline on the stack, and so cannot
  be `null`. This can solved by "boxing" the value: storing it in a wrapper
  class, such as `Integer` for boxing `int`s, but this imposes an overhead as
  now every operation on the value must follow a pointer to some potentially
  uncached memory (and types that can be represented in less than a word of
  memory, such as `byte`, must now be represented as a word-size pointer). The
  other potential solution is to use some other "dummy" value to represent a
  missing entry: for example `java.util.Arrays.binarySearch`{.java} returns an
  `int` representing the 0-based position in an array that a key was found at,
  or else a negative integer to indicate that no such key was found. However,
  not every primitive type has such a "dummy" value: if a function needs to
  return either `true`, `false` or a sentinal value the indicate no return
  value, there is no third value in `boolean` that can be used as the dummy value.
  
The solution is to do away entirely with `null`, and introduce an algebraic
datatype with 2 variants: one for when the value is present, and one for when it
is absent.

In Haskell:
```haskell
data Maybe a = Nothing | Just a
```

In Rust:
```rust
enum Option<T> {
    None,
    Some(T),
}
```

Now we have solved all the attendant problems `null` brings: 

* **More accurate type signatures**: If a function accepts a `T`, it is an error
  to attempt to pass an `Option<T>` to it.
* **Different cases are separated by the type system**: our hypothetical hashmap
  of student degrees would become `HashMap<String, Option<Degree>>`{.rust}, and `get`
  returns an `Option<Option<Degree>>`{.rust}: `None` for the case where the
  student is not present, `Some(None)` for when the student has not yet
  graduated, and `Some(Some(...))` for when the student is present and graduated.
* **It is general enough**: any type can be wrapped in an `Option`, not just
  heap-allocated types

Walrus inherits Rust's `enum`s, however because the type system is currently
monomorphic (does not support generic functions or datatypes), a separate `enum`
must be declared for each instantiation of the `Option<T>` type:

```rust
enum IntOption {
    None{},
    Some{val: Int},
}
```

##### Error handling
As well as potentially-missing data, algebraic datatypes can be used to
represent potentially-erroneous data: one variant for the "correct" data, and
one for the data representing an error:

In Haskell:
```haskell
data Either a b = Left a | Right b
```

In Rust:
```rust
enum Result<T,E> {
    Ok(T),
    Err(E),
}
```

The same can be expressed in Walrus, though again, because of limitations in the
type system, each instance of `Result<T,E>` must be monomorphised:

```rust
enum IntStringResult {
    Ok{x: Int},
    Err{e: String},
}
```

The `Result` enum can be used to replace *exceptions* as used in many other
programming languages for error handling.
TODO: advantages of `Result` over exceptions

## Pattern Matching {#sec:reference:pattern-matching}
Pattern-matching allows matching against complex, potentially nested data. First
introduced by TODO in TODO, pattern-matching quickly became a staple feature of
functional programming languages, but has yet to break into more common
mainstream languages. For those unfamiliar with it, it can be though of as a
`switch` statement from C or Java, only generalised to work over all datatypes,
and to allow binding of variables: Each *case* is matched against a value in
order, and the right hand side of the first case to match is evaluated.

The most basic patterns are *literal patterns*. In this case `match` operates
exactly the same as `case`. Note that the *wildcard-pattern*, `_`, matches any
possible value, analogous to a `default` branch in a `switch` statement:
```rust
fn is_zero(x: Int) -> Bool {
    match x {
        0 => true,
        _ => false,
    }
}
```

Patterns may also bind variables. Using an identifier as a pattern also matches
any value, but also introduces a new variable bound to the value it matched
against:
```rust
fn is_zero(x: Int) -> Bool {
    match x {
        0 => true,
        y => {
            print("x is not zero: it is " + int_to_string(y));
            false
        }
    }
}
```

As well as matching against primitive datatypes, aggregate types can be matched
against, using the same syntax as their corresponding expression syntax:

```rust
fn add_pair(p: (Int, Int)) -> Int {
    match p {
        (x, y) => x + y,
    }
}
```

```rust
fn person_to_string(p: Person) {
    match p {
        Person{age, name, weight} => name + "is " + int_to_string(age) 
                                     + " years old and weighs " 
                                     + float_to_string(weight),
    }
}
```

```rust
fn colour_to_string(c: Colour) -> String {
    match c {
        Colour::Red{} => "red",
        Colour::Green{} => "green",
        Colour::Blue{} => "blue",
    }
}
```

Patterns can of course be nested within each other:
```rust
fn add_options(x: IntOption, y: IntOption) -> IntOption {
    match (x, y) {
        (IntOption::Some{val: x}, IntOption::Some{val: y}) => IntOption::Some{val: x + y}
        (IntOption::Some{val}, _) => IntOption::Some{val},
        (_, IntOption::Some{val}) => IntOption::Some{val},
        _ => IntOption::None,
    }
}
```

### Exhaustive matches
Ideally, each `match` expression should be checked for *exhaustiveness*: that
is, that every possible value being matched against is covered in at least one
case. Walrus does not yet check `match` expressions for exhaustiveness, as the
algorithm for checking exhaustiveness is quite complex.

### Irrefutable patterns {#sec:reference:irrefutable-patterns}
Pattern matching can take place is several other Walrus constructs, not just the
`match` expression. In particular, let-statements, function arguments, and
lambda arguments all allow arbitrary patterns to be used, not just simple
variable names. However, since these pattern-matching constructs only give one
possible case to match against, the pattern being matched against must be
*irrefutable* - ie it must not be possible for the pattern to fail. This means
that literal and enum patterns are not allowed.

## Type System {#sec:reference:types}
Previous sections of this reference have mentioned *types* and Walrus'
*type-system*, but the terms have not been properly described. This section will
define what a type and a type-system is, and how Walrus' type system in
particular works, as well as its present limitations. 

### Types and type-systems
In every (non-trivial) programming language it is possible to express programs
are *syntatically-correct* but nevertheless *semantically-incorrect*: that is,
the program text is parsed by the compiler/interpreter to form a valid abstract
syntax tree, but the program represented by the abstract syntax tree produces
some sort of error at runtime, whether an error may be a fatal condition that
causes execution to abort, or worse, causes the program to silently calculate an
incorrect value. 

As programmers, we would like to be assured that our programs are in fact
semantically-correct before we run them, so that we can detect errors and
correct them at development-time, rather than after the program has been
deployed. The field of *formal-methods* describes several methods for checking
the correctness of programs, such as automated-theorem provers, model-checkers,
and Hoare logic. The most widespread method for checking correctness is to use a
*type-system*. *Types and Programming Languages*, widely regarded
as the definitive textbook on type-systems and thier use in programming
languages, describes a type system as:

> a tractable syntactic method for proving the absence of certain program
> behaviors by classifying phrases according to the kinds of values they
> compute.

That is, each value has an associated *type*, which describes (amongst other
properties) the valid operations that may be performed on values of that type.
For example, it is meaningful to attempt to divide one rational number by
another, but it is not meaningful to attempt the same operation on two strings.
The *type-system* of a particular programming-language is the set of rules that
describe what operations may be performed on which types, how types are assigned
to values, and how simpler types may be combined to form more complex types.

#### Static vs Dynamic type systems
Type-systems may be classified as either *static* or *dynamic*. In a
*dynamically-typed* language, each value carries around a *type-tag* at runtime
to indicate its type, whilst in a *statically-typed* language, the type of value
produced by each expression is known *statically* (that is, before the program
is run). Some people call dynamically-typed languages such as Python or
Javascript "untyped", but this is a misnomer: these languages still have rules
about what is and is not a valid operation on certain classes of values - the
checking that the program conforms to these rules is simply deferred to runtime.


TODO: benefits of static type systems over dynamic type systems

### The Walrus Type System {#sec:reference:type-system}
The Walrus type system is a simplification of the Rust type system, which is
itself an extension of the classic *Hindley-Milner* type system.

The original Hindley-Milner type system, introduced in (TODO) by (TODO),
provides a set of inferences rules for determining a single "most general type"
for expressions in the *simply-typed λ-calculus*. For the purposes of this
report, it is sufficient just to be aware that the simply-typed *λ*-calculus
is a very primitive programming language, providing only *variables*,
*application* (call a function with exactly one argument), *abstraction*
(creating an anonymous function of exactly one argument) and *let-binding*
(binding a variable to a value, and evaluating a second expression in the
extended environment).

Modern day functional programming languages use the simply-typed *λ*-calculus
(or some other *λ*-calculi) as their underlying theory, while adding
extensions to produce a language practical for real-world development. Walrus is
no exception: its extensions to the simply-typed *λ*-calculus include:

* Primitive types and corresponding literals
* Global variables
* Algebraic datatypes and pattern matching
* Functions and function-calls with zero or more arguments
* *Side-effects* via assignment or builtin functions such as `print`
* Control flow via `if`, `loop`, `return`, `break` and `continue`
* Limited subtyping, in the form of the `Never` type

#### Forming types
Types in Walrus are either one of the primitive types, a new abstract type
introduced by the `struct` or `enum` types, or a combination of already existing
types into functions or tuples.

#### Primitive types
As described in @sec:reference:primitive-types, each primitive datatype has an
associated type (`Bool`, `Int`, `Float`, `Char` and `String`). The `Never` type
is also a primitive type, but it has no associated values (see
@sec:reference:types:never).

#### Function types
Function types describe the types of functions, in terms of the types of
parameters they accept, and the type of the value returned. The syntax of
function types is simply the types of each parameter to the left of an arrow,
and the type of the value returned to the right of the arrow. Note that the
arrow is right associative: that is `(Int) -> (Bool) -> Int` is the same as
`(Int) -> ((Bool) -> Int)`, which are both distinct from `((Int) -> Bool) -> Int`:
```rust
() -> ()                 // A function taking 0 parameters, and returning nothing (the empty tuple)

(Int) -> Int             // A function taking 1 Int and returning an Int

(Int, Bool) -> Int       // A function taking 1 Int and 1 Bool, and returning an Int

(Int) -> (Bool) -> Int   // A function taking 1 Int and returning a function 
                         // which in turn takes 1 Bool and returns an Int

(Int) -> ((Bool) -> Int) // The same type, with explicit parentheses to 
                         // indicate associativity of `->`

((Int) -> Bool) -> Int   // A function which takes a function from 1 Int to a Bool, 
                         // and returns an Int
```

#### Type inference
TODO

#### Inhabitants
When discussing properties of certain types, it can be useful to consider the
number of different values a type may take. These values are called the
*inhabitants* of a type. For example, the `Bool` type has two inhabitants:
`true` and `false`; the `Int` type has $2^32$ inhabitants (the integers in the
range $-2^-31$ and $2^31-1$ inclusive). The number of inhabitants of aggregate
types can be computed recursively: for tuples and structs, it is the product of
the number of inhabitants of each fields, and for enums, it is the sum of the
number of inhabitants of each variant.

Of particular interest are types with exactly 1 inhabitant (a *unit-type*), and
types with 0 inhabitants (an *uninhabited* or *empty-type*).

##### The unit type {#sec:reference:types:unit}

A type is called *a unit-type* if it has exactly 1 inhabitant. In Walrus such
types are either the 0-tuple, `()`, or a `struct` with 0 fields, such as
```rust
struct UnitStruct {}
```
or an `enum` with exactly 1 variant which has 0 fields:
```rust
enum UnitEnum {
    A{}
}
```

Types with 1 inhabitant may also be constructed by combining other unit types:
```rust
struct AlsoAUnit {
    a: (),
    b: ((), ()),
    c: UnitStruct,
    d: UnitEnum,
}
```

Since all these types have only one inhabitant, it is useful to pick one to be
*the* unit type, and consider all others as *isomorphic* ^[That is, each unit
type can be safely converted to *the* unit type without any loss of information]
to it. In Walrus, the cannonical unit type is the 0-tuple, `()`. For this
reason, `()` is also sometimes called "*the* unit type" or "the unit tuple".

Since any unit type has exactly 1 possible value, it carries no information at
runtime: that is, it can be represented by zero bits. This makes unit types
natural placeholders for when some type is needed, but no information is
returned. It is for this reason that functions with empty bodies/no trailing
expression return `()`, and assignment expression expressions evaluate to `()`.
Unit types can be considered analogous to the `void` type from C, however unlike
C's `void`, values of unit types are first class values that can be stored in
variables, passed to and returned from functions, etc.

##### The bottom type {#sec:reference:types:never}

A *bottom-type* is a type with 0 inhabitants: it is *uninihabited*. In Walrus'
such types are either the primitive type `Never`, an `enum` with 0 variants:
```rust
enum EmptyEnum {}
```
or combinations thereof, such as a tuple or struct where any field has 0
inhabitants:
```rust
struct UnihabitedStruct {
    a: Int,
    b: Int,
    c: (Never, ()),
}
```
Just as `()` is *the* canonical unit-type, `Never` is *the* canonical bottom
type in Walrus.

Since any bottom-type has 0 possible values, it carries even less information
than a unit type: a value of a bottom-type cannot even exist at runtime! This
allows meaningful types to be given to expressions that never return flow of
control back to the enclosing scope after they are evaluated. For example, a
`loop` expression with no `breaks` inside it will never terminate, and so has
type `Never`: such a loop will never produce any value. Similarly, the builtin
function `exit` returns `Never`: once the `exit` function is called, the process
executing the program exits, and so the enclosing context will never recieve a
value. Perhaps more strangely, all the control flow altering expressions,
`return`, `break`, `continue` also have type `Never`. This is because, like
`exit`, when such an expression is evaluated, the enclosing scope is exited and
control is transferred to elsewhere in the program. Note that although the
`return` and `break` expressions themselves have type `Never`, they alter the
return type of their enclosing function/loop: the return type of the enclosing
function becomes the type of the argument to `return`, or `()` if it has no
argument, and the same for the enclosing `loop` in the case of `break`.

TODO: c++ `[[noreturn]]`

A useful property of `Never` is that it may be *coereced* to any other
type. Suppose a programmer wishes to write an `assert` function, which checks
that the condition passed to it is true, or else aborts the program:
```rust
fn assert(cond: Bool) {
    if cond {
        // do nothing
    } else {
        print("assertion failed");
        exit(1);
    }
}
```
In the case where the condition is true, `assert` simply does nothing. If the
condition is false, it prints an error and calls the builtin `exit`. Since the
type of the false branch is `Never`, it automatically coerces to the type of the
other branch, in this case `()`, and thus the type of the whole function body
satisfies the `()` return type of the function.

This behaviour may seem confusing, but it is in fact perfectly valid. Since a
value of a bottom-type cannot exist, we are free to promise that it could take
the role expected of it by any other type - since such a value is impossible, we
will never be asked to make good on our promise.

This behaviour also describes why such types are called "bottom types": in a
type-system with subtyping, a bottom type is a subtype of all other types
(including itself and all other bottom types). Note that Walrus does not have a
subtyping mechanism: `Never` is the only type that may be passed to a context
expecting a different type.

TODO IF TIME: Curry-Howard Isomoprhism, Principle of Explosion

#### Limitations {#sec:reference:types:limitations}
##### No quantification
The largest limitation in the current type-system of Walrus is that it is
entirely *monomorphic*: that is, although the Walrus compiler is able to infer a
type for every expression and function, the type must cannot *quantify* over
other types. Therefore, we can write an identity function, but any given
implementation will only work for one particular type of argument. We cannot
write an identity function that works over all types; instead the function must
be repeated for every type of argument we wish to pass to it.

```rust
fn int_identity(x: Int) -> Int {
    x
}

fn float_identity(x: Float) -> Float {
    x
}
```
This is clearly tedious and requires the programmer to needlessly duplicate an
indentical function. If Walrus' type system could quantify over other types, we
could write an identity function that could be called with any argument type.
Such functions are called *generic* in C++, Java and Rust, or *polymorphic* in
Haskell ^[Here we copy the generics syntax of Rust for the sake of example]:
```rust
fn identity<T>(x: T) -> T {
    x
}
```

The same problem extends to defining structs and enums. We cannot write a single
`Option<T>` enum that can wrap any type. Instead, we must write an identical
`enum` for each type that we wish to wrap:
```rust
enum IntOption {
    None,
    Some{val: Int},
}

enum FloatOption {
    None,
    Some{val: Int},
}
```

##### No overloading
Walrus' type system also lacks *overloading*: the ability for a single function
(or operator) to share several implementations with the same name but different
types. This is the mechanism that allows, for example, Java to have a single
`toString` method which is able to convert any type to a string representation,
where the logic to convert a datatype to a string representation may be very
different depending on the type.

Although *overloading* and *polymorphism* both allow a single function name to
operate on different types, overloading is more flexible than polymorphism. A
polymorphic function must have exactly the same behaviour for each type of
argument passed to it, and it must be valid for any possible type of argument.
In otherwords, a polymorphic function cannot perform any type-specific
operations on its arguments: it can only shuffle them around. Thus it is
possible to write a polymorphic identity function, or a polymorphic
list-reversal function, but not a polymorphic `to_string` function or a
polymorphic list-sorting function. By contrast, an overloaded function *can*
select a different implementation according to the types of its arguments, and
an overloaded function can only be called with types that have an overload
defined for them.

It is for these reasons that Walrus has several different `to_string` functions
for each of the primitive datatypes, and why its operators cannot be passed
around as first-class values. By being builtin syntactic constructs, the type
checker can handle operators as a special, limited form of overloading, where
some operators can be applied to more than one type, but the set of types they
can be applied to is fixed. To allow an overloaded operator or function to be
passed around as a value, the type-system must be able to assign a single most
general type to overloaded functions or operators. This requires a form of
polymorphism known as *ad-hoc polymorphism* ^[The previous, most simple form of
polymorphism we have talked about is sometimes called *parametric-polymorphism*
to distinguish it from other more advanced forms of polymorphism]

TODO: first introduced by ??? for Haskell 

In a system with *ad-hoc polymorphism*, polymorphic functions can be
additionally augmented with *type-constraints* - a set of requirements that a
type variable must satisfy. Consider the Rust function `max`:
```rust
fn max<T: Ord>(v1: T, v2: T) -> T;`
```

This function can only be called on types for which a way to compare them has
been defined. In Rust, requirements are called *traits*, and a type fulfills the
requirements of a trait by providing an *implementation* of the trait ^[The real
Rust `Ord` trait has its own constraints that we will ignore for the sake of
simplicity of this example]:

```rust
enum Ordering {
    Less,
    Equal,
    Greater,
}

trait Ord<T> {
    fn cmp(v1: T, v2: T) -> Ordering;
}

impl Ord for i32 {
    fn cmp(v1: i32, v2: i32) -> Ordering {
        if v1 < v2 {
            Ordering::Less
        } else if v2 > v1
            Ordering::Greater
        else {
            Ordering::Equal
        }
    }
}
```

It would be desirable to add a similar system to Walrus. However, the
implementation of type checking for a trait system is far from simple, and so
has been left out of the current Walrus implementation.
