# Evaluation {#sec:eval}
We will now retrospectively evaluate the Walrus language against the criteria
given in @sec:intro, and then discuss potential directions for further
development of the project.

## Achievements

### Correctness
We believe that by introduction of carefully chosen language features, we have
been able to replace problematic features that can be sources of crashes or bugs
in other programs. 

* By providing the ability to define algebraic data types in the form of
  *enums*, we have replaced the misfeature of *null-pointers*/*null-references*
  We have also improved on the *tagged-union* design pattern from C - the
  contents of Walrus enums are impossible to access without first checking which
  variant the enum currently occupies (see @sec:reference:enums).
* By both requiring that variables be initialised in let-statements (see
  @sec:reference:initialisation) and by omitting *constructor methods* and
  requiring all fields of a struct/enum to be initialised up
  front(@sec:reference:structs), we have eliminated any potential for undefined
  behaviour arising from accessing uninitialised variables.
* The choice of string representation removes the potential for memory safety
  bugs due to manual string manipulation (@sec:impl:llvm:strings)

There are unfortunately two potential sources of undefined behaviour remaining
in Walrus: 

Firstly, the results of the arithmetic operators, `+`, `-`, `*`, and `/` are
not checked for overflow or division by zero. Let us take division by zero as an
example. The following Walrus program will trigger undefined behaviour when
compiled with `-O3`, but not with `-O0`:
```rust
fn main() {
    let x = 42;
    let y = 0;
    print(int_to_string(x/y));
}
```

When compiled and run with `-O0`, this program crashes with the message
`floating point exception (core dumped)`, but with `-03`, it prints `1`. Some
kind of undefined behaviour must be occurring for the behaviour to differ
between optimisation levels, since optimisations must maintain the semantics of
UB-free programs. Comparing the LLVM IR before and after optimisation reveals
the difference:

When compiling with `-O0`, the program will load the values `42` and `0` into
two registers and execute some integer-division instruction. Since this attempts
a division by zero, a floating point exception is thrown by the CPU and Linux
kills the program.
```
%String = type { i32, i8* }

define {} @main() {
main.entry:
  %x.alloca = alloca i32, align 4
  store i32 42, i32* %x.alloca, align 4
  %y.alloca = alloca i32, align 4
  store i32 0, i32* %y.alloca, align 4
  %x = load i32, i32* %x.alloca, align 4
  %y = load i32, i32* %y.alloca, align 4
  %Int.div = sdiv i32 %x, %y
  %int_to_string.call = call %String @builtin_int_to_string(i32 %Int.div)
  %print.call = call {} @builtin_print(%String %int_to_string.call)
  ret {} zeroinitializer
}

declare %String @builtin_int_to_string(i32)

declare {} @builtin_print(%String)
```

When compiling with `-O3`, LLVM replaces all reads from `x` and `y` by their
constant values (*copy progagation*), and then performs constant folding on the
division, which is now a division of two constants, `42/0`. Division by zero in
the `sdiv` instruction is undefined behaviour^[TODO cite
https://llvm.org/docs/LangRef.html#sdiv-instruction], and so the instruction is
replaced by `undef`. In this particular compilation, LLVM chose to replace that
particular instance of `undef` by `1` when translating to machine code, but this
behaviour can not be relied on and could change without warning in future
versions of LLVM.
```
%String = type { i32, i8* }

define {} @main() local_unnamed_addr {
main.entry:
  %int_to_string.call = tail call %String @builtin_int_to_string(i32 undef)
  %print.call = tail call {} @builtin_print(%String %int_to_string.call)
  ret {} zeroinitializer
}

declare %String @builtin_int_to_string(i32) local_unnamed_addr

declare {} @builtin_print(%String) local_unnamed_addr
```

The other source is inexhaustive pattern matching. Consider this program, which
prints `0` when run with `-O0` but `42` when run with `-03`.

```rust
fn main() {
        let x = false;
        let y = 
        match x {
                true => 42,
        };
        print(int_to_string(y));
}
```

With `-O0` the IR looks like this:
```
%String = type { i32, i8* }

define {} @main() {
main.entry:
  %x.alloca = alloca i1, align 1
  store i1 false, i1* %x.alloca, align 1
  %x = load i1, i1* %x.alloca, align 1
  br label %match.case0.test

match.case0.test:                                 ; preds = %main.entry
  %Bool.eq = icmp eq i1 %x, true
  br i1 %Bool.eq, label %match.case0.then, label %match.fail

match.case0.then:                                 ; preds = %match.case0.test
  br label %match.end

match.fail:                                       ; preds = %match.case0.test
  unreachable

match.end:                                        ; preds = %match.case0.then
  %match.phi = phi i32 [ 42, %match.case0.then ]
  %y.alloca = alloca i32, align 4
  store i32 %match.phi, i32* %y.alloca, align 4
  %y = load i32, i32* %y.alloca, align 4
  %int_to_string.call = call %String @builtin_int_to_string(i32 %y)
  %print.call = call {} @builtin_print(%String %int_to_string.call)
  ret {} zeroinitializer
}

declare %String @builtin_int_to_string(i32)

declare {} @builtin_print(%String)
```
This time the source of UB is the `unreachable` instruction in `match.fail`,
which we introduced as a placeholder value until we can reject this program at
compile time for failing to consider the case when `x` is `false`. 

When compiling with `-O3`, LLVM reduces the entire program to
```
define {} @main() local_unnamed_addr #0 {
main.entry:
  unreachable
}

attributes #0 = { norecurse noreturn nounwind readnone }
```

This time it seems that the `unreachable` instruction is being executed at both
optimisation levels, but something happens during the optimisation process that
causes `unreachble` to become a `0` in one case and a `42` in the other.

### High-level abstractions
The combination of first class functions, pattern matching and algebraic data
types allows us to express many functional programming design patterns in
Walrus. For example, in @sec:appendix:lists, we are able to inductively define
linked lists as either `Nil` or `Cons`, exactly as one would in Haskell or
Ocaml. We go on to define various functions over lists - `length`, `append`,
`reverse`, `map` and `fold`. With the addition of polymorphic functions and data
types, Walrus could provide a `List` type in a standard library, just like
Haskell.

Of course, Walrus does not yet have polymorphic functions or data types, and
this severely restricts the reusability of the `List` data type we defined. We
can only have lists of `Int`, and we can only map them to lists of `Int`, or
fold them to `Int`.

### User experience
#### Error reporting
Both the presentational style and content of error messages can have a large
impact on the user experience of the programmer - error messages should clearly
indicate **where** in the program the error occurred, preferably by underlining
the offending section of code or even highlighting it in bold colours; and
provide an understandable explanation of **what** the error means and how it can
be fixed. The design of error messages is more an art than a science: languages
like Rust and Elm, which pride themselves on compiler user experience, have
extensive developer guidelines for writing helpful error messages and will
sometimes even go as far as to tell the user what they can type to fix the error
^[TODO: links].

Obviously a single-person project over the course of a year will not have quite
the same level of polish attached to the content of error messages, however I
am very pleased with the visual presentation of error messages: each error
message underlines and highlights the offending code. 

A selection of error messages is demonstrated by this erroneous program:
```rust
fn a() {
    b(1, 2, 3);
}

fn b(x: Int, y: Int) -> Int {x + y}

fn c() {
    99999999999999999999999;
    "hello \z world";
    '\u{999999}';
}

fn d() {
    let f = 0.5;
    f(1);
}

fn e() {
    let x = 5;
    x = 6;
}

fn g() {
    1 + "hello";
}
```

which produces the following error messages:

![](img/errors.png)

#### Error recovery
One caveat of the error-recovering compilation strategy is that in solving the
problem of reporting too few errors, we swing too far in the opposite direction
and report too many errors. Consider this simple 3 line program:

```rust
fn add(x, y) -> _ {
    x + y
}
```

Since the `+` operator can be applied to either `Int`s, `Float`s and `String`s,
and none of the variables are annotated with a type, we do not have enough
information to determine a unique type for `x` and `y` (the system of equality
constraints is said to be *under-constrained*). This leads to a cascade of
further type inference error messages, as now the type of the function body and
all its sub-expressions cannot be inferred, and each sub-expression emits a new
error message. Therefore, while ideally this program should result in just 3
error messages (could not infer type of `x`, could not infer type of `y`, could
not infer return type of `add`), in reality 11 error messages are produced - too
many to even fit in one terminal screen at my normal font size:

![](img/too-many-errors-1.png)
![](img/too-many-errors-2.png)

This shows some logic will be needed to decide which error messages are
important enough to emit and which can be omitted, as they have been covered by
other error messages, whilst ensuring that no error is left "uncovered" with no
error message referring to it (we want to avoid a situation where errors exist
but no error message about them is emitted). Just like design of error messages,
deciding which error messages to emit and which to omit is an art, not a science.

### Performance
This is the aspect of the language that we can evaluate with the least amount of
certainty. While we are confident that Walrus should fit comfortably in the
middle tier of languages in terms of performance - faster than dynamically
typed, interpreted languages such as Python, but slower than statically typed
systems languages such as Rust or C++ - we have not had the time to perform any
benchmarks. This estimation is simply our intuition considering that Walrus is
compiled to native code ahead of time, and is able to provide plenty of
information to LLVM in the form of static types that it can use in optimisation
analyses. This is pure conjecture however, and humans are notoriously bad at
estimating program performance.

## Future directions

### Pattern exhaustiveness

### Polymorphism

### Parser error recovery

### Garbage collection

### Module system