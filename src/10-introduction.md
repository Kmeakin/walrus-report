# Introduction {#sec:intro}

## Project description
In this project, we present the *Walrus* programming language: a language
syntatically similar to the C-like family of language, but adopting many
features more common in functional-programming languages. The result is a
language where functional design patterns like *higher-order functions* and
*immutable data structures* are encouraged, but imperative features like
*mutation* and *early return* are still available for when a pure functional
formulation is inelegant. In the course of this project we have designed the
language, implemented a compiler for it, and formally specified its syntax and
typing rules.

## Report Structure
This report consists of 4 sections:

* **Introduction**: what goals we hope the language will fullfil, and
  inspirations in its design.
* **Reference**: a detailed language reference along with example programs and
  rationales for design decisions where appropraite. 
* **Implementation**: a walkthrough of the Walrus compiler pipeline - every stage
  that a program passes through to get from source code to machine code.
* **Evaluation**: a retrospective evaluation of the Walrus language agaisnt our
  project goals, and directions for future investigation.

## Project goals
When designing the language, we selected 4 principles that we wanted Walrus to
fulfill.

These are by no means the only criteria by which langauges can be judged: choice
and priority of criteria will be determined by the language's intended use and
target audience:

* A scripting langauge intended for small "glue" scripts will likely value
  low-barriers to entry and fast development time over correctness or
  performance. This is exactly the tradeoff made by Bash, where the lack of a
  type system allows any program written in any programming language to be used
  as a library function - when all functions communicate by reading and writing
  strings, there is no need to convert between different types. However this
  lack of discipline also tends to produce brittle scripts which do not handle
  invalid input or unexpected conditions such as missing files.
* A systems language intended for development of operating systems
  is likely to prioritise performance above all else: for example, the C++
  language community expects new abstractions added to the language to be
  "zero-cost", in the words of Bjarne Stroustrup, its original developer: "What
  you don’t use, you don’t pay for. And further: What you do use, you couldn’t
  hand code any better." This leads to a reluctance to add new features until it
  can be shown that they can be implemented with zero performance cost.
* An academic language intended for research is likely to focus on adding
  elaborate new features and proving various formal properties of the language's
  semantics, rather than on delivering high performance or being easily easily
  accessible to programmers without a grounding in programming language theory.

Our language does not fill any of those niches. It is intended to be a "general
purpose" language for writing commandline or desktop applications, the kind of
task for which one might use languages such as Java, or Go.

### Correctness and safety
TODO: distinction between correctness and safety? there can be a lot of overlap

We believe that programming languages are above all a tool for producing
software, and that the software produced by such tools should be *correct* and
*safe*. We consider correctness and safety to be non-negotiable: there is no use
in sacrificing correctness for speed if the result is that the programs can
produce the wrong result faster.

By correct, we mean that the program produces the expected result with respect
to a specification of the program. Total program correctness is impossible
without resorting to formal verification (and even then it is undeciable in the
general case), and indeed few programs even have a formal specification. However
it is possible to increase confidence in program correctness through
introduction of features such as a strong type system (see @sec:ref:type-system
for a definition of *strong* typing vs *weak* typing), and omission of features
that are easy to use incorrectly, such as untagged unions (TODO: ref), null
references (TODO: ref), or constructor methods (TODO: ref).

Safety is a more nebulous concept. It can best be desribed as the absence of
certain disasterious situations, such as the program crashing due to attempting
to access privelleged memory, or exposing a security vulnerability due to a
buffer overflow. It is possible for a program to be safe, but incorrect: for
example, a C program whose intention is to print the string "hello world" but
whose implementation consists of a single call to `printf("goodbye world")` is
safe, but it is not correct.

Since it can often be hard to distinguish between a program that is incorrect or
a program that is unsafe, we have grouped both under one goal.

#### Undefined behaviour
A key component of ensuring both correctness and safety is the avoidance of
*undefined-behaviour*. Undefined behaviour is any situation where the expected
behaviour of the program is not specified by the language specification.
Undefined behaviour is common in the C and C++ programming languages, both
because of variation in the specified behaviour of an operation on each platform
(such as signed integer overflow or out of bounds bitshifts), or because
attempting to detect the erroneous condition at runtime would be excessively
costly in terms of performance (such as checking that each pointer is not null
before dereferencing it). 

The C++ standard states that compilers are free to give whatever
semantics they desire to undefined behaviour:

> Permissible undefined behavior ranges from ignoring the situation completely
> with unpredictable results, to behaving during translation or program
> execution in a documented manner characteristic of the environment (with or
> without the issuance of a diagnostic message), to terminating a translation or
> execution (with the issuance of a diagnostic message).
> -- C++20 standard^[TODO: citation]

This means that it is impossible to reason about the correctness of a program
that triggers undefined behaviour, since (in theory) literally anything could
happen. C and C++ folklore warns of such disasterous results as reformatting the
user's hard-drive, launching missiles, or causing demons to fly out of the
user's nose.^[http://catb.org/jargon/html/N/nasal-demons.html]

Clearly, a crucial condition of Walrus' safety will be that it does not contain
any undefined behaviour: the behaviour of every operation should be defined in
the specification, and care should be taken that the machine code emitted
matches the stated behaviour.

### High-level abstractions
The language should not require the user to pay attention to details that are
not relevant to the program being written, or that could be feasibly inferred by
the compiler. The details of manual memory management may be relevant to someone
writing an operating systems kernel or a program with particularly high
performance requirements, but they are not relevant to the vast majority of
programs as long as performance remains acceptable. Similarly, type annotations
are an irrelevant detail if the correct annotations can be inferred by the
compiler in most situations.

The language should also provide features that allow the programmer to solve
problems at a higher level of abstraction or without writing excessive
boilerplate code. In our experience this is often achieved through the use of
features from functional programming such as higher order functions,
polymorphism, and algebraic datatypes.

### Performance
The language should not produce programs that are needlessly slow to execute. Of
course, everyone always wants faster programs; it is a question of what
tradeoffs the language makes in order to acheive it.

Systems languages such as C++ and Rust are willing to significantly complicate
the model of the language in order to squeeze the last few drops of performance
out of their programs: for example, Rust's borrow checker allows memory safety
to be achieved without the use of a garbage collector, at the cost of requiring
the programmer to provide lifetime annotations, and also hinders the ability of
the programmer to build abstractions as high level as those seen in more
functional languages such as Haskell.

We believe that the combination of native compilation via LLVM and a static type
system will make Walrus programs "fast enough" for most common applications,
even in the presence of garbage collection.

## Inspirations
Throughout this report we may make references to other programming languages, in
order to compare certain design or implementation decisions to the same
decisions made in other languages. Knowledge of an imperative programming
language such as C, C++ or Java is assumed. Knowledge of Rust and of a
functional programming language such as Haskell could also be helpful to better
understand some of the comparisons, but is not absolutetly necessary.

A key inspiration of the design of the Walrus language is the Rust language.
Rust does indeed fulfill many of the design criteria we gave earlier. It
guarantees that undefined behaviour will not be triggered, unless the programmer
specifically opts in via use of the `unsafe` keyword to indicate that the code
cannot be checked but is nevertheless safe. It provides high level abstractions
such as type inference, algebraic datatypes and pattern pattern matching.
However, as we mentioned above, Rust's unwavering pursuit of performance
requires the programmer to give undue attention to details of memory management
that are often not relevant and limits the power of abstraction capabilities. 

Since we agree with many of the design decisions taken by Rust, we have often
looked to Rust for inspiration in the design of the syntax and semantics of
Walrus, whilst simplifying those aspects that we believe are unnecesarily
complex for Walrus' lower performance requirements. Our hope is that Walrus will
be attractive to other users of Rust admire many of its design choices but who
share our frustration at the limitations imposed by its high performance
requirements.
