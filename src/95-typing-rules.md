## Type inference {#sec:appendix:type-rules}

### Type values
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
       &   | & \Gamma, var : \tau   & \text{extended environment} \\
\end{longtable}

\begin{mathpar}
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
\end{mathpar}

TODO: put this somewhere else: If the premise of a rule refers to "occurs", this rule only applies to that
instance of the expression

### Definitions
TODO

### Expressions
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
\Gamma \vdash e_0: \tau_k^0 \\ \dots \\ \Gamma \vdash e_n: \tau_k^{n_k}
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
\Gamma \vdash param_0: \tau_0 \\
\dots \\
\Gamma \vdash param_n: \tau_n \\
\Gamma \vdash e: \tau \\ 
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
\Gamma \vdash stmt_0: \tau_0 \\
\dots \\
\Gamma \vdash stmt_n: \tau_n \\
\Gamma \vdash e: \tau \\
}
{\Gamma_0 \vdash \{ stmt_{0}, \dots, stmt_{n}, e \}: \tau }

\inferrule*[right=BlockNoTrailingExpr] 
{
\Gamma \vdash stmt_0: \tau_0 \\
\dots \\
\Gamma \vdash stmt_n: \tau_n \\
}
{\Gamma \vdash \{ stmt_{0}, \dots, stmt_{n} \} : () }

\inferrule*[right=MatchExpr] 
{
\Gamma \vdash e: \tau \\
\Gamma \vdash p_0: \tau \\
\dots \\
\Gamma \vdash p_n: \tau \\
\Gamma \vdash e_0: \tau' \\
\dots \\
\Gamma \vdash e_n: \tau' \\
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

\inferrule*[right=FnDef] 
{
 \Gamma, param_{0}: \tau_{0} \vdash e : \tau' \\
 \Gamma \vdash t : \tau' \\
 \Gamma \vdash param_{0} : \tau_{0} \ \dots \ \Gamma \vdash param_{n} : \tau_{n} \\
 \text{There is a function definition of the form $\texttt{fn} \ v(param_{0}, \dots,
 param_{n}) \to t \  \{ e \} $} \\
 }
{\Gamma \vdash v : (\tau_{0}, \dots, \tau_{n}) \to \tau'}
\end{mathparpagebreakable}

