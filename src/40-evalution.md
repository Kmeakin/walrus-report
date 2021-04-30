# Evaluation {#sec:eval}

## Achievements

### Correctness

### High-level abstractions

### Performance

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
error message. Therefore, while idealy this program should result in just 3
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

## Future directions

### Pattern exhaustiveness

### Polymorphism

### Garbage collection

### Module system

### Parser error recovery