# Appendix {#sec:appendix}
## Lexer {#sec:appendix:lexer}

```rust
#[derive(Logos)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TokenKind {
    #[error] Error,
    #[regex(r"\s+")] Whitespace,
    #[regex(r"//[^\n]*")] LineComment,
    #[token(r"/*", lex_block_comment)] BlockComment,

    #[token("break")] KwBreak,
    #[token("continue")] KwContinue,
    #[token("else")] KwElse,
    #[token("enum")] KwEnum,
    #[token("false")] KwFalse,
    #[token("fn")] KwFn,
    #[token("if")] KwIf,
    #[token("let")] KwLet,
    #[token("loop")] KwLoop,
    #[token("match")] KwMatch,
    #[token("mut")] KwMut,
    #[token("return")] KwReturn,
    #[token("struct")] KwStruct,
    #[token("true")] KwTrue,

    #[regex(r"(\p{XID_Start}|_)\p{XID_Continue}*")] Ident,
    #[regex(r"[0-9][0-9_]*")]         DecInt,
    #[regex(r"(0b|0B)[0-1][0-1)]*")]  BinInt,
    #[regex(r"(0x|0X)[0-9a-fA-F][0-9a-fA-F_]*")]  HexInt,
    #[regex(r"[0-9][0-9_]*\.[0-9][0-9_]*")] Float,
    #[regex(r"'[^']'")]                              SimpleChar,
    #[regex(r"'\\.'")]                               EscapedChar,
    #[regex(r"'\\(u|U)\{[0-9a-fA-F][0-9a-fA-F_]*\}'")] UnicodeChar,
    #[regex(r#""([^"]|\\")*""#)] String,

    #[token("(")] LParen,
    #[token(")")] RParen,
    #[token("{")] LCurly,
    #[token("}")] RCurly,

    #[token(".")] Dot,
    #[token(",")] Comma,
    #[token(";")] Semicolon,
    #[token(":")] Colon,
    #[token("::")] ColonColon,
    #[token("->")] ThinArrow,
    #[token("=>")] FatArrow,
    #[token("_")] Underscore,

    #[token("+")] Plus,
    #[token("-")] Minus,
    #[token("*")] Star,
    #[token("/")] Slash,

    #[token("!")] Bang,
    #[token("&&")] AndAnd,
    #[token("||")] OrOr,

    #[token("=")] Eq,
    #[token("==")] EqEq,
    #[token("!=")] BangEq,
    #[token("<")] Less,
    #[token("<=")] LessEq,
    #[token(">")] Greater,
    #[token(">=")] GreaterEq,
}

fn lex_block_comment(lexer: &mut Lexer) {
    const OPEN: &str = "/*";
    const CLOSE: &str = "*/";

    let mut level = 1;
    while level > 0 && !lexer.remainder().is_empty() {
        let src = lexer.remainder();

        if src.starts_with(OPEN) {
            level += 1;
            lexer.bump(OPEN.len());
        } else if src.starts_with(CLOSE) {
            level -= 1;
            lexer.bump(CLOSE.len());
        } else {
            lexer.bump(src.chars().next().unwrap().len_utf8())
        }
    }
}

#[derive(Copy, Clone, PartialEq)]
pub struct Token<'a> {
    pub span: Range<usize>,
    pub kind: TokenKind,
    pub text: &'a str,
}

pub fn lex(src: &str) -> impl Iterator<Item = Token> {
    let mut lexer = Lexer::new(src);
    iter::from_fn(move || {
        let kind = lexer.next()?;
        let text = lexer.slice();
        let span = lexer.span();
        Some(Token { span, kind, text })
    })
}
```


## HIR {#sec:appendex:hir}
```rust
pub type VarId = Idx<Var>;
pub type FnDefId = Idx<FnDef>;
pub type StructDefId = Idx<StructDef>;
pub type EnumDefId = Idx<EnumDef>;
pub type ExprId = Idx<Expr>;
pub type TypeId = Idx<Type>;
pub type PatId = Idx<Pat>;

pub struct Program {
    pub decls: Vec<Decl>,
    pub hir: HirData,
    pub source: ProgramSource,
    pub diagnostics: Vec<Diagnostic>,
}

#[derive(Debug, Clone, PartialEq, Default)]
pub struct HirData {
    pub vars: Arena<Var>,
    pub fn_defs: Arena<FnDef>,
    pub struct_defs: Arena<StructDef>,
    pub enum_defs: Arena<EnumDef>,
    pub exprs: Arena<Expr>,
    pub types: Arena<Type>,
    pub pats: Arena<Pat>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ModuleSource {
    pub vars: HashMap<VarId, syntax::Var>,
    pub fn_defs: HashMap<FnDefId, syntax::FnDef>,
    pub struct_defs: HashMap<StructDefId, syntax::StructDef>,
    pub enum_defs: HashMap<EnumDefId, syntax::EnumDef>,
    pub exprs: HashMap<ExprId, syntax::Expr>,
    pub types: HashMap<TypeId, syntax::Type>,
    pub pats: HashMap<PatId, syntax::Pat>,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Decl {
    Fn(FnDefId),
    Struct(StructDefId),
    Enum(EnumDefId),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FnDef {
    pub name: VarId,
    pub params: Vec<Param>,
    pub ret_type: Option<TypeId>,
    pub expr: ExprId,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct Param {
    pub pat: PatId,
    pub ty: Option<TypeId>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct StructDef {
    pub name: VarId,
    pub fields: Vec<StructField>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EnumDef {
    pub name: VarId,
    pub variants: Vec<EnumVariant>,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct StructField {
    pub name: VarId,
    pub ty: TypeId,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EnumVariant {
    pub name: VarId,
    pub fields: Vec<StructField>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Lit(Lit),
    Var(VarId),
    Tuple(Vec<ExprId>),
    Field {
        expr: ExprId,
        field: Field,
    },
    Struct {
        name: VarId,
        fields: Vec<FieldInit>,
    },
    Enum {
        name: VarId,
        variant: VarId,
        fields: Vec<FieldInit>,
    },
    Unop {
        op: Unop,
        expr: ExprId,
    },
    Binop {
        lhs: ExprId,
        op: Binop,
        rhs: ExprId,
    },
    Call {
        func: ExprId,
        args: Vec<ExprId>,
    },
    Block {
        stmts: Vec<Stmt>,
        expr: Option<ExprId>,
    },
    Loop(ExprId),
    If {
        test: ExprId,
        then_branch: ExprId,
        else_branch: Option<ExprId>,
    },
    Match {
        test: ExprId,
        cases: Vec<MatchCase>,
    },
    Break(Option<ExprId>),
    Return(Option<ExprId>),
    Continue,
    Lambda {
        params: Vec<Param>,
        expr: ExprId,
    },
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct MatchCase {
    pub pat: PatId,
    pub expr: ExprId,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct FieldInit {
    pub name: VarId,
    pub val: Option<ExprId>,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Field {
    Tuple(u32),
    Named(VarId),
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Unop {
    Not,
    Add,
    Sub,
}

#[derive(Debug, Display, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Binop {
    Lazy(LazyBinop),
    Arithmetic(ArithmeticBinop),
    Cmp(CmpBinop),
    Assign,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum LazyBinop {
    Or,
    And,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum ArithmeticBinop {
    Add,
    Sub,
    Mul,
    Div,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum CmpBinop {
    Eq,
    NotEq,
    Less,
    LessEq,
    Greater,
    GreaterEq,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Stmt {
    Let {
        pat: PatId,
        ty: Option<TypeId>,
        expr: ExprId,
    },
    Expr(ExprId),
}

#[derive(Debug, Clone, PartialEq)]
pub enum Lit {
    Bool(bool),
    Int(u32),
    Float(f32),
    Char(char),
    String(SmolStr),
}

#[derive(Debug, Clone, PartialEq)]
pub enum Pat {
    Lit(Lit),
    Var {
        is_mut: bool,
        var: VarId,
    },
    Ignore,
    Tuple(Vec<PatId>),
    Struct {
        name: VarId,
        fields: Vec<FieldPat>,
    },
    Enum {
        name: VarId,
        variant: VarId,
        fields: Vec<FieldPat>,
    },
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct FieldPat {
    pub name: VarId,
    pub pat: Option<PatId>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Type {
    Var(VarId),
    Infer,
    Tuple(Vec<TypeId>),
    Fn { params: Vec<TypeId>, ret: TypeId },
}
```

## Typing rules {#sec:appendix:type-rules}

\begin{mathpar}
\inferrule [BoolLit]
{ }
{\Gamma \vdash b : Bool} 

\inferrule [IntLit]
{ }
{\Gamma \vdash i: Int} 

\inferrule [FloatLit]
{ }
{\Gamma \vdash f: Float} 

\inferrule [CharLit]
{ }
{\Gamma \vdash c: Char} 

\inferrule [StringLit]
{ }
{\Gamma \vdash s: String} 

\inferrule [VarExpr]
{v: \tau \in \Gamma}
{\Gamma \vdash v: \tau} 

\inferrule [TupleExpr]
{\Gamma \vdash e_{0} : \tau_{0} \dots \Gamma \vdash e_{n} : \tau_{n}}
{\Gamma \vdash (e_{0}, \dots, e_{n}) : (\tau_{0}, \dots, \tau_{n})}

\inferrule [LambdaExpr] 
{\Gamma \vdash p_{0} : \tau_{0} \dots \Gamma \vdash p_{n} : \tau_{n} \\
 \Gamma \vdash e: \tau'}
{\Gamma \vdash (p_{0}, \dots, p_{n}) \Rightarrow e : (\tau_{0}, \dots, \tau_{n}) \to \tau'}

\inferrule [CallExpr] 
{\Gamma \vdash e' : (\tau_{0}, \dots, \tau_{n}) \to \tau' \\ 
 \Gamma \vdash e_{0} : \tau_{0} \dots \Gamma \vdash e_{n} : \tau_{n}}
{\Gamma \vdash e'(e_{0}, \dots, e_{n}) : \tau'}
\end{mathpar}