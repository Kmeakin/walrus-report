## Typing rules {#sec:appendix:type-rules}
If the premise of a rule refers to "occurs", this rule only applies to that
instance of the expression

\begin{mathpar}
\inferrule*[right=BoolLit]
{ }
{\Gamma \vdash b : \textbf{Bool}} 

\inferrule*[right=IntLit]
{ }
{\Gamma \vdash i: \textbf{Int}} 

\inferrule*[right=FloatLit]
{ }
{\Gamma \vdash f: \textbf{Float}} 

\inferrule*[right=CharLit]
{ }
{\Gamma \vdash c: \textbf{Char}} 

\inferrule*[right=StringLit]
{ }
{\Gamma \vdash s: \textbf{String}} 

\inferrule*[right=VarExpr]
{v: \tau \in \Gamma}
{\Gamma \vdash v: \tau} 

\inferrule*[right=TupleExpr]
{\Gamma \vdash e_{0} : \tau_{0} \dots \Gamma \vdash e_{n} : \tau_{n}}
{\Gamma \vdash (e_{0}, \dots, e_{n}) : (\tau_{0}, \dots, \tau_{n})}

\inferrule*[right=LambdaExpr] 
{\Gamma \vdash param_{0} : \tau_{0} \dots \Gamma \vdash param_{n} : \tau_{n} \\
 \Gamma \vdash e: \tau}
{\Gamma \vdash (param_{0}, \dots, param_{n}) \Rightarrow e : (\tau_{0}, \dots, \tau_{n}) \to \tau}

\inferrule*[right=CallExpr] 
{\Gamma \vdash e' : (\tau_{0}, \dots, \tau_{n}) \to \tau \\ 
 \Gamma \vdash e_{0} : \tau_{0} \ \dots \ \Gamma \vdash e_{n} : \tau_{n}}
{\Gamma \vdash e'(e_{0}, \dots, e_{n}) : \tau}

\inferrule*[right=IfThenElseExpr] 
{\Gamma \vdash e_{1} : \textbf{Bool} \\ 
 \Gamma \vdash e_{2} : \tau \\
 \Gamma \vdash e_{3} : \tau
}
{\Gamma \vdash \texttt{if} \ e_{1} \ e_{2} \ \texttt{else} \ e_{3} : \tau}

\inferrule*[right=IfThenExpr] 
{\Gamma \vdash e_{1} : \textbf{Bool} \\ 
 \Gamma \vdash e_{2} : () \\
}
{\Gamma \vdash \texttt{if} \ e_{1} \ e_{2} : ()}

\inferrule*[right=NonterminatingLoopExpr] 
{\Gamma \vdash e' : \tau \\
 \text{\texttt{break} $e'$ does not occur in $e$}
}
{\Gamma \vdash \texttt{loop} \ e : \textbf{Never}}

\inferrule*[right=TerminatingLoopExpr] 
{\Gamma \vdash e : \tau' \\
 \Gamma \vdash e_{1}: \tau \dots \Gamma \vdash e_{n}: \tau \\
 \text{\texttt{break} $e_{1}$ \dots \ \texttt{break} $e_{n}$ occur in $e_{1}$}
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
{\Gamma \vdash e_{1} : \tau \\
 \text{\texttt{return} $e$ occurs in a function or lambda expr}
}
{\Gamma \vdash \texttt{return} \ e : \textbf{Never}}

\inferrule*[right=BlockExpr] 
{\Gamma \vdash e : \tau}
{\Gamma \vdash \{ stmt_{0}; \dots; stmt_{n}; \ e \} : \tau }

\inferrule*[right=BlockNoExpr] 
{ }
{\Gamma \vdash \{ stmt_{0}; \dots; stmt_{n}; \} : () }

\inferrule*[right=FnDef] 
{
 \Gamma, param_{0}: \tau_{0} \vdash e : \tau' \\
 \Gamma \vdash t : \tau' \\
 \Gamma \vdash param_{0} : \tau_{0} \ \dots \ \Gamma \vdash param_{n} : \tau_{n} \\
 \text{There is a function definition of the form $\texttt{fn} \ v(param_{0}, \dots,
 param_{n}) \to t \  \{ e \} $} \\
 }
{\Gamma \vdash v : (\tau_{0}, \dots, \tau_{n}) \to \tau'}
\end{mathpar}

