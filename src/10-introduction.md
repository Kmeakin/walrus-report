# Introduction {#sec:intro}

## Project description
In this report we present the Walrus programming language, which aims to achieve
correctness, high-level abstraction and performance. This is achieved by
adoption of features commonly found in functional programming languages, such as
first class functions, algebraic data types and type inference, whilst retaining
familiar imperative features such as mutation and early return for when a purely
functional formulation of a program is inelegant.

In the course of this executing this project we have designed the Walrus
language, implemented a compiler for it, and formally specified its syntax and
typing rules.

## Report Structure
This report consists of 4 sections:

* **Introduction**: The criteria we hope the language will fulfil, and
  inspirations in its design.
* **Reference**: A detailed language reference along with example code and
  rationales for design decisions where appropriate. 
* **Implementation**: A walkthrough of the Walrus compiler pipeline - every
  stage that a program passes through to get from source code to machine code.
* **Evaluation**: A retrospective evaluation of the Walrus language against our
  project goals, and directions for future investigation.

## Project goals
When designing the language, we selected several criteria that we wanted Walrus
to fulfil.

These are by no means the only criteria by which languages can be judged: choice
and priority of criteria will be determined by the language's intended use and
target audience:

* A scripting language intended for small "glue" scripts will likely value
  low barriers to entry and fast development time over correctness or
  performance. This is exactly the trade-off made by Bash, where the lack of a
  type system allows any program written in any programming language to be used
  as a library function - when all functions communicate by reading and writing
  strings, there is no need to convert between different types. However this
  lack of discipline also tends to produce brittle scripts which do not handle
  invalid input or unexpected conditions such as missing files.
* A systems language intended for development of operating systems
  is likely to prioritise performance above all else: for example, the C++
  language community expects new abstractions added to the language to be
  "zero-cost":

  > What you don’t use, you don’t pay for. And further: What you do use, you
  > couldn’t hand code any better." This leads to a reluctance to add new
  > features until it can be shown that they can be implemented with zero
  > performance cost.
  > --Bjarne Stroustrup

  This leads to a reluctance to add new features until it can be shown that they
  can be implemented with zero performance cost.

* An academic language intended for research is likely to focus on adding
  elaborate new features and proving various formal properties of the language's
  semantics, rather than on delivering high performance or being easily easily
  accessible to programmers without a grounding in programming language theory.

Our language does not fill any of those niches. It is intended to be a "general
purpose" language for writing command-line or desktop applications, the kind of
task for which one might use languages such as Java or Go.

### Correctness
We believe that programming languages are above all a tool for producing
software, and that the software produced by such tools should be *correct*. 

By correct, we mean that the program produces the expected result with respect
to a specification of the program.  Incorrect programs can at best crash with an
indication of where the error occurred, silently produce an incorrect answer but
continue execution, or at worst produce a correct seeming answer but create a
security vulnerability such as a buffer overflow.

Total program correctness is impossible without resorting to formal verification
(and even then it is undecidable in the general case), and indeed few programs
even have a formal specification. However it is possible to increase confidence
in program correctness through introduction of static analyses such as static type
systems, and omission of features that are easy to use incorrectly, such as
untagged unions (TODO: ref).

We consider correctness to be non-negotiable: there is no use in sacrificing
correctness for speed if the result is that the programs can produce the wrong
result faster.

#### Undefined behaviour
A key component of ensuring correctness is the avoidance of
*undefined-behaviour*. Undefined behaviour is any situation where the expected
behaviour of the program is not specified by the semantics of the language or
the program being executed on. Undefined behaviour is common in the C and C++
programming languages, both because of variation in the specified behaviour of
an operation on each platform (such as signed integer overflow or bit-shifts by
more than the bit-width, which vary according to the instruction set
architecture), or because attempting to detect the erroneous condition at
runtime would be excessively costly in terms of performance (such as checking
that each pointer is not null before dereferencing it). 

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
happen: C and C++ folklore warns of such disastrous results as reformatting the
user's hard-drive, launching missiles, or causing demons to fly out of the
user's nose.^[http://catb.org/jargon/html/N/nasal-demons.html]

In practice most compilers simply assume that undefined behaviour cannot occur.
From the point of view of the compiler this is a useful interpretation of the
standard, since it allows them to perform extra optimisations making more
assumptions about the user's code. However, this can still be problematic, as it
can leads to the compiler eliding safety checks inserted by the programmer or
producing unexpected results. 

Clearly, a crucial condition of Walrus' correctness will be that it does not contain
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
polymorphism, and algebraic data types.

### Performance
The language should not produce programs that are needlessly slow to execute. Of
course, everyone always wants faster programs; it is a question of what
trade-offs the language makes in order to achieve it.

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

### User experience {#sec:intro:user-experience}
It is not enough for a compiler to simply detect that a program is incorrect. It
should also provide enough information to the programmer for them to correct the
program. In other words, the compiler should exhibit both good *error-reporting*
and good *error-recovery*.

Error-reporting is the ability of a compiler to accurately report the location
of the offending code that was responsible for a syntactic or semantic error,
and to provide a meaningful message describing the error. Line drawings and
coloured output highlighting the offending code can make identifying the
location of the error much easier for the reader. The compiler may even go so
far as to suggest what the offending code should be replaced with.

Error-recovery is the ability of a compiler to continue with syntactic or
semantic analysis in the presence of an error. This is important for a good user
experience because it allows subsequent errors to be detected, and so more
errors can be reported by a single invocation of the compiler. The more errors
that can be detected in one invocation, the fewer trips around the
*edit-compile-run cycle* (the loop between writing new code, compiling it,
correcting errors and recompiling) will be required during development, and so the
more productive the programmer feels.

Improving user experience should not require trading off on any of the other
listed criteria (other than taking away from time that could be spent on other
aspects of the compiler), as user experience is a property of the particular
implementation of the compiler, not the design of the language itself.

## Inspirations
Throughout this report we may make references to other programming languages, in
order to compare certain design or implementation decisions to the same
decisions made in other languages. Knowledge of an imperative programming
language such as C, C++ or Java is assumed. Knowledge of Rust and of a
functional programming language such as Haskell could also be helpful to better
understand some of the comparisons, but is not absolutely necessary.

A key inspiration of the design of the Walrus language is the Rust language.
Rust does indeed fulfil many of the design criteria we gave earlier. It
guarantees that undefined behaviour will not be triggered, unless the programmer
specifically opts in via use of the `unsafe` keyword to indicate that the code
cannot be checked but is nevertheless safe. It provides high level abstractions
such as type inference, algebraic data types and pattern pattern matching.
However, as we mentioned above, Rust's unwavering pursuit of performance
requires the programmer to give undue attention to details of memory management
that are often not relevant and limits the power of abstraction capabilities. 

Since we agree with many of the design decisions taken by Rust, we have often
looked to Rust for inspiration in the design of the syntax and semantics of
Walrus, whilst simplifying those aspects that we believe are unnecessarily
complex for Walrus' lower performance requirements. Our hope is that Walrus will
be attractive to other users of Rust admire many of its design choices but who
share our frustration at the limitations imposed by its high performance
requirements.

