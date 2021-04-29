## Type inference {#sec:appendix:type-rules}
We define two relations. First, the relation $\llbracket t \rrbracket = \tau$
maps the abstract syntax of a HIR type to a representation of the type after all
named types have been resolved to either builtin types or structs/enums. The
second relation, $x: \tau$, maps various HIR nodes to thier inferred types. Some
of the inference rules will yeild two conclusions: a type for the node being
inspect, and a new environment. This allows passing around new environments as
they are extended. The *environment*, $\Gamma$, maps variables to the type of
their denotation, and is initialised such that each builtin is mapped to the
type of its denotation.

### Evaluating types
\begin{longtable}{RRLL}
\tau & ::= & \textbf{Bool}                      & \text{primitive types} \\
     &   | & \textbf{Int}                       &                        \\
     &   | & \textbf{Float}                     &                        \\
     &   | & \textbf{Char}                      &                        \\
     &   | & \textbf{String}                    &                        \\
     &   | & \textbf{Never}                     &                        \\
     &   | & v \ \{ v_0: \tau_0, \dots, v_n: \tau_n \}  & \text{struct type} \\
     &   | & v \ \{ v'_0 \ \{ v_0^0: \tau_0^0, \dots, v_0^{n_0}: \tau_0^{n_0} \}, \dots, v'_n \ \{ v_n^0: \tau_n^0, \dots, v_n^{n_n}: \tau_n^{n_n} \} \} & \text{enum type}       \\
     &   | & \alpha                             & \text{type variable}   \\
     &   | & (\tau_0, \dots, \tau_n)            & \text{tuple type}      \\
     &   | & (\tau_0, \dots, \tau_n) \to \tau   & \text{function type}   \\
\\
\Gamma & ::= & \{
\texttt{Bool}: \textbf{Bool}, \dots, \texttt{exit}: (\textbf{Int}) \to \textbf{Never}
\}            & \text{initial environment}    \\
       &   | & \Gamma \cup \{var : \tau\}   & \text{extended environment} \\
\end{longtable}

\begin{mathparpagebreakable}
\inferrule*[right=VarType]
{v: \tau \in \Gamma}
{\Gamma \vdash \llbracket v \rrbracket = \tau} 

\inferrule*[right=PlaceholderType]
{ }
{\Gamma \vdash \llbracket \_ \rrbracket = \alpha} 
\

\inferrule*[right=TupleType]
{\Gamma \vdash \llbracket t_0 \rrbracket = \tau_0  \\
\dots  \\
\Gamma \vdash \llbracket t_n \rrbracket = \tau_n \\
}
{\Gamma \vdash \llbracket (t_0, \dots, t_n) \rrbracket = (\tau_0, \dots, \tau_n)} 

\inferrule*[right=FnType]
{\Gamma \vdash \llbracket t_0 \rrbracket = \tau_0  \\
\dots  \\
\Gamma \vdash \llbracket t_n \rrbracket = \tau_n \\
\Gamma \vdash \llbracket t \rrbracket = \tau \\
}
{\Gamma \vdash \llbracket (t_0, \dots, t_n) \to t \rrbracket = (\tau_0, \dots,
\tau_n) \to \tau} 
\
\end{mathparpagebreakable}


### Definitions
\begin{mathparpagebreakable}
\inferrule*[right=FnDef] 
{
\tau' = (\alpha_0, \dots, \alpha_n) \to \alpha \\
\Gamma' = \Gamma \cup \{ v: \tau' \}    \\
\Gamma' \vdash \llbracket t \rrbracket = \tau \\
\Gamma' \vdash param_0: \tau_0, \Gamma_1 \\ 
\dots \\
\Gamma_n \vdash param_n: \tau_n, \Gamma_{n+1} \\ 
\Gamma_{n+1} \vdash e : \tau \\
}
{
\Gamma_0 \vdash \texttt{fn} \ v (param_0, \dots, param_n) \to t \ \texttt{do} \ e: \tau' \\
\Gamma'
}

\inferrule*[right=StructDef] 
{
\tau' = v \ \{ v_0: \alpha_0, \dots, v_n: \alpha_n \} \\
\Gamma' = \Gamma \cup \{ v: \tau' \}    \\
\Gamma' \vdash \llbracket t_0 \rrbracket = \tau_0 \\
\dots \\
\Gamma' \vdash \llbracket t_n \rrbracket = \tau_n \\
}
{
\Gamma_0 \vdash \texttt{struct} \ v \ \{ v_0: t_0, \dots, v_n: t_n \} : \tau' \\
\Gamma'
}

\inferrule*[right=EnumDef] 
{
\tau' = v \{ v'_0 \ \{ v_0^0: \alpha_0^0, \dots, v_0^{n_0}: \alpha_0^{n_0} \}, \dots, v'_n \ \{ v_n^0: \alpha_n^0, \dots, v_n^{n_n}: \alpha_n^{n_n} \} \} \\
\Gamma' = \Gamma \cup \{ v: \tau' \}    \\
\Gamma' \vdash \llbracket t_0^0 \rrbracket = \tau_0^0 \\
\dots \\
\Gamma' \vdash \llbracket t_n^{n_n} \rrbracket = \tau_n^{n_n} \\
}
{
\Gamma \vdash \texttt{enum} \ v \ 
\{ 
v'_0 \ \{ v_0^0: t_0^0, \dots, v_0^{n_0}: t_0^{n_0} \},
\dots,
v'_n \ \{ v_n^0: t_n^0, \dots, v_n^{n_n}: t_n^{n_n} \}
\} : \tau' \\
\Gamma'
}
\end{mathparpagebreakable}

### Parameters
\begin{mathparpagebreakable}
\inferrule*[right=AnnotatedParam] 
{
\Gamma \vdash p: \tau, \Gamma' \\
\llbracket t \rrbracket = \tau \\
}
{
\Gamma \vdash p: \tau \\
\Gamma'
}

\inferrule*[right=Param] 
{\Gamma \vdash p: \tau, \Gamma'}
{
\Gamma \vdash (p : t): \tau \\
\Gamma'
}
\end{mathparpagebreakable}

### Literals
\begin{mathparpagebreakable}
\inferrule*[right=BoolLit]
{ }
{\Gamma \vdash bool : \textbf{Bool}} 

\inferrule*[right=IntLit]
{ }
{\Gamma \vdash int: \textbf{Int}} 

\inferrule*[right=FloatLit]
{ }
{\Gamma \vdash float: \textbf{Float}} 

\inferrule*[right=CharLit]
{ }
{\Gamma \vdash char: \textbf{Char}} 

\inferrule*[right=StringLit]
{ }
{\Gamma \vdash string: \textbf{String}} 
\end{mathparpagebreakable}

### Expressions
\begin{mathparpagebreakable}
\inferrule*[right=VarExpr]
{v: \tau \in \Gamma}
{\Gamma \vdash v: \tau} 

\inferrule*[right=VarExpr]
{v: \tau \in \Gamma}
{\Gamma \vdash v: \tau} 

\inferrule*[right=TupleExpr]
{\Gamma \vdash e_{0} : \tau_{0}\\
\dots\\
\Gamma \vdash e_{n} : \tau_{n}}
{\Gamma \vdash (e_{0}, \dots, e_{n}) : (\tau_{0}, \dots, \tau_{n})}

\inferrule*[right=StructExpr]
{
v: v \ \{ v_0: \tau_0, \dots, v_n: \tau_n \} \in \Gamma\\
\Gamma \vdash e_0: \tau_0 \\ \dots \\ \Gamma \vdash e_n: \tau_n
}
{\Gamma \vdash v \ \{ v_0: e_0, \dots, v_n: e_n \}: v \ \{ v_0: \tau_0, \dots, v_n: \tau_n \}}

\inferrule*[right=EnumExpr]
{
v: v \ \{ \dots, v'_k \ \{ v_k^0: \tau_k^0, \dots, v_k^{n_k}: \tau_k^{n_k} \}, \dots \} \in \Gamma\\
\Gamma \vdash e_0: \tau_k^0 \\ \dots \\ \Gamma \vdash e_{n_k}: \tau_k^{n_k}
}
{\Gamma \vdash v::v'_k \ \{ v_k^0: e_0, \dots, v_k^n: e_{n_k} \}: v \ \{ \dots, v'_k \ \{ v_k^0: \tau_k^0, \dots, v_k^{n_k}: \tau_k^{n_k} \}, \dots \}}

\inferrule*[right=StructFieldExpr] 
{\Gamma \vdash e : v \ \{ \dots, v_k: \tau_k, \dots \}}
{\Gamma \vdash e.v_k : \tau_k}

\inferrule*[right=TupleFieldExpr] 
{\Gamma \vdash e : (\dots, \tau_k, \dots)}
{\Gamma \vdash e.k : \tau_k}

\inferrule*[right=ArithmeticUnaryExpr] 
{
\Gamma \vdash e: \tau \\
\circledast \in \{ -,+ \} \\
\tau \in \{ \textbf{Int}, \textbf{Float} \} \\
}
{\Gamma \vdash \circledast \ e: \tau}

\inferrule*[right=BooleanUnaryExpr] 
{\Gamma \vdash e: \textbf{Bool}}
{\Gamma \vdash ! e: \textbf{Bool}}

\inferrule*[right=CmpBinopExpr] 
{
\Gamma \vdash e_1: \tau\\
\Gamma \vdash e_2: \tau\\
\circledast \in \{\equiv,\nequiv,<,\leq,>,\geq \} \\
\tau \in \{ \textbf{Bool}, \textbf{Int}, \textbf{Float}, \textbf{Char}, \textbf{String} \}
}
{\Gamma \vdash e_1 \circledast e_2: \textbf{Bool}}

\inferrule*[right=ArithmeticBinopExpr] 
{
\Gamma \vdash e_1: \tau\\
\Gamma \vdash e_2: \tau\\
\circledast \in \{ +,-,*,/ \} \\
\tau \in \{ \textbf{Int}, \textbf{Float} \}
}
{\Gamma \vdash e_1 \circledast e_2: \tau}

\inferrule*[right=StringAppendExpr] 
{
\Gamma \vdash e_1: \textbf{String}\\
\Gamma \vdash e_2: \textbf{String}\\
}
{\Gamma \vdash e_1 + e_2: \textbf{String}}

\inferrule*[right=BoolBinopExpr] 
{
\Gamma \vdash e_1: \textbf{Bool}\\
\Gamma \vdash e_2: \textbf{Bool}\\
\circledast \in \{ \land, \lor \} \\
}
{\Gamma \vdash e_1 \circledast e_2: \textbf{Bool}}

\inferrule*[right=AssignmentExpr] 
{
\Gamma \vdash e_1: \tau \\
\Gamma \vdash e_2: \tau \\
\text{$e_1$ is an lvalue} \\
\text{$e_1$ is mutable} \\
}
{\Gamma \vdash e_1 = e_2: ()}

\inferrule*[right=CallExpr] 
{
\Gamma \vdash e: (\tau_0, \dots, \tau_n) \to \tau \\ 
\Gamma \vdash e_0: \tau_0 \\
\dots \\
\Gamma \vdash e_n: \tau_n \\
}
{\Gamma \vdash e(e_0, \dots, e_n) : \tau}

\inferrule*[right=LambdaExpr] 
{
\Gamma_0 \vdash param_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_n \vdash param_n: \tau_n, \Gamma_{n+1} \\
\Gamma_{n+1} \vdash e: \tau \\ 
}
{\Gamma \vdash \lambda(param_0, \dots, param_n) \Rightarrow e : (\tau_0, \dots, \tau_n) \to \tau}

\inferrule*[right=IfThenElseExpr] 
{
\Gamma \vdash e_{1} : \textbf{Bool} \\ 
\Gamma \vdash e_{2} : \tau \\
\Gamma \vdash e_{3} : \tau \\
}
{\Gamma \vdash \texttt{if} \ e_{1} \ \texttt{then} \ \ e_{2} \ \texttt{else} \ e_{3} : \tau}

\inferrule*[right=IfThenExpr] 
{
\Gamma \vdash e_{1} : \textbf{Bool} \\ 
\Gamma \vdash e_{2} : \tau \\
}
{\Gamma \vdash \texttt{if} \ e_{1} \ \texttt{then} \ e_{2} : ()}

\inferrule*[right=BlockExpr] 
{
\Gamma_0 \vdash stmt_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_n \vdash stmt_n: \tau_n, \Gamma_{n+1} \\
\Gamma_{n+1} \vdash e: \tau \\
}
{\Gamma_0 \vdash \{ stmt_{0}, \dots, stmt_{n}, e \}: \tau }

\inferrule*[right=BlockNoTrailingExpr] 
{
\Gamma_0 \vdash stmt_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_n \vdash stmt_n: \tau_n, \Gamma_{n+1} \\
}
{\Gamma_0 \vdash \{ stmt_{0}, \dots, stmt_{n} \} : () }

\inferrule*[right=ExprStmt] 
{\Gamma \vdash e: \tau}
{\Gamma \vdash e; : \tau}

\inferrule*[right=AnnotatedLetStmt] 
{
\Gamma \vdash \llbracket t \rrbracket = \tau \\
\Gamma \vdash e: \tau \\
\Gamma \vdash p: \tau, \Gamma' \\
}
{\Gamma \vdash \texttt{let} \ p: t = e; : (), \Gamma'}

\inferrule*[right=LetStmt] 
{
\Gamma \vdash e: \tau \\
\Gamma \vdash p: \tau, \Gamma' \\
}
{\Gamma \vdash \texttt{let} \ p = e; : (), \Gamma'}

\inferrule*[right=MatchExpr] 
{
\Gamma \vdash e: \tau \\
\Gamma \vdash p_0: \tau, \Gamma_0 \\
\dots \\
\Gamma \vdash p_n: \tau, \Gamma_n \\
\Gamma_0 \vdash e_0: \tau' \\
\dots \\
\Gamma_n \vdash e_n: \tau' \\
}
{\Gamma \vdash \texttt{match} \ e \ \{ p_0 \Rightarrow e_0, \dots, p_n \Rightarrow e_n \}: \tau'}

\inferrule*[right=NonterminatingLoopExpr] 
{\Gamma \vdash e' : \tau \\
 \text{\texttt{break} $e'$ does not occur in $e$}
}
{\Gamma \vdash \texttt{loop} \ e : \textbf{Never}}

\inferrule*[right=TerminatingLoopExpr] 
{
\Gamma \vdash e : \tau' \\
\Gamma \vdash e_{1}: \tau\\
\dots \\
\Gamma \vdash e_{n}: \tau \\
\text{\texttt{break} $e_{1}$ \dots \ \texttt{break} $e_{n}$ occur in $e$} \\
}
{\Gamma \vdash \texttt{loop} \ e : \tau}

\inferrule*[right=BreakExpr] 
{\Gamma \vdash e : \tau \\
 \text{\texttt{break} $e$ occurs in a \texttt{loop}}
}
{\Gamma \vdash \texttt{break} \ e : \textbf{Never}}

\inferrule*[Right=ContinueExpr] 
{\text{\texttt{continue} occurs in a \texttt{loop}}}
{\Gamma \vdash \texttt{continue} : \textbf{Never}}

\inferrule*[right=ReturnExpr] 
{
\Gamma \vdash e: \tau \\
\text{\texttt{return} $e$ occurs in a function or $\lambda$ expression} \\
}
{\Gamma \vdash \texttt{return} \ e : \textbf{Never}}
\end{mathparpagebreakable}

### Patterns
\begin{mathparpagebreakable}
\inferrule*[right=VarPat]
{ }
{
\Gamma \vdash v: \alpha \\ 
\Gamma \cup \{ v: \alpha \} 
} 

\inferrule*[right=IgnoredPat]
{ }
{\Gamma \vdash \_: \alpha} 

\inferrule*[right=TuplePat]
{ 
\Gamma_0 \vdash p_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_n \vdash p_n: \tau_n, \Gamma_{n+1} \\
}
{
\Gamma_0 \vdash (p_0, \dots, p_n): (\tau_0, \dots, \tau_n) \\
\Gamma_{n+1}
} 

\inferrule*[right=StructPat]
{ 
v: v \ \{ v_0: \tau_0, \dots, v_n: \tau_n \} \in \Gamma_0\\
\Gamma_0 \vdash p_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_n \vdash p_n: \tau_n, \Gamma_{n+1} \\
}
{
\Gamma_0 \vdash v \ \{ v_0: p_0, \dots, v_n: p_n \}: v \ \{ v_0: \tau_0, \dots, v_n: \tau_n \} \\
\Gamma_{n+1}
} 

\inferrule*[right=EnumPat]
{ 
v: v \ \{ \dots, v_k' \ \{ v_k^0: \tau_k^0, \dots, v_k^{n_k}: \tau_k^{n_k} \}, \dots \} \in \Gamma_0\\
\Gamma_0 \vdash p_0: \tau_0, \Gamma_1 \\
\dots \\
\Gamma_{n_k} \vdash p_{n_k}: \tau_{n_k}, \Gamma_{n_k+1} \\
}
{
\Gamma_0 \vdash v \ \{ v_k^0: p_k^0, \dots, v_k^{n_k}: p_k^{n_k} \}: v \{ \dots, v_k' \ \{ v_k^0: \tau_k^0, \dots, v_k^{n_k}: \tau_k^{n_k} \}, \dots \} \\
\Gamma_{n_k+1}
} 
\end{mathparpagebreakable}