## Lists in Walrus

```rust
enum List {
    Nil {},
    Cons {head: Int, tail: List}
}

// Get the number of elements in a List
fn length(l: List) -> Int {
    match l {
        List::Nil{} => 0,
        List::Cons{head,tail} => 1 + length(tail),
    }
}

/// Convert a List to a String
fn list_to_string(l: List) -> String {
    match l {
        List::Nil{} => "[]",
        List::Cons{head, tail} => "[" + int_to_string(head) + list_to_string_helper(tail) + "]",
    }
}

fn list_to_string_helper(l: List) -> String {
    match l {
        List::Nil{} => "",
        List::Cons{head, tail} => ", " + int_to_string(head) + list_to_string_helper(tail),
    }
}

/// Append two Lists together
fn append(l1: List, l2: List) -> List {
    match l1 {
        List::Nil{} => l2,
        List::Cons{head,tail} => List::Cons{head, tail: append(tail,l2)},
    }
}

/// Reverse a List
fn reverse(l: List) -> List {
    reverse_helper(l, List::Nil{})
}

fn reverse_helper(l: List, acc: List) -> List {
    match l {
        List::Nil{} => acc,
        List::Cons{head,tail} => reverse_helper(tail, List::Cons{head, tail: acc})
    }
}
 
/// Apply `f` to every element of a List
fn map(l: List, f: (Int) -> Int) -> List {
    match l {
        List::Nil {} => List::Nil{},
        List::Cons{head, tail} => List::Cons{head: f(head), tail: map(tail, f)}
    }
}

/// Repeatedly apply `f` to every element of a List until 
/// it is reduced to a single value
fn fold(l: List, acc: Int, f: (Int, Int) -> Int) -> Int {
    match l {
        List::Nil{} => acc,
        List::Cons{head, tail} => fold(tail, f(acc, head), f)
    }
}

/// Add all the elements of a List together
fn sum(l: List) -> Int {
    fold(l, 0, (x, y) => x + y) 
}

/// Multiply all the elements of a List together
fn product(l: List) -> Int {
    fold(l, 1, (x, y) => x * y) 
}

fn main() -> _ {
    let l1 = List::Cons {
        head: 4,
        tail: List::Cons {
            head: 3,
            tail: List::Cons {
                head: 2,
                tail: List::Cons {
                    head: 1,
                    tail: List::Nil {},
                },
            },
        },
    };
    print(list_to_string(l1) + "\n");

    let l2 = map(l1, (x) => x * x);
    print(list_to_string(l2) + "\n");

    let l3 = append(l1,l2);
    print(list_to_string(l3) + "\n");

    let l4 = reverse(l3);
    print(list_to_string(l4) + "\n");

    let len = length(l3);
    print("length: " + int_to_string(len) + "\n");
    
    let s = sum(l3);
    print("sum: " + int_to_string(s) + "\n");

    let p = product(l3);
    print("product: " + int_to_string(p) + "\n");
}
```