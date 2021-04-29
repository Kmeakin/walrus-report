## Abstract Syntax {#sec:appendix:hir}
$$
\begin{array}{rrll}
var & & & \text{variable} \\
\\
n   & & & \text{natural number} \\
\\
fn & ::= & \texttt{fn} \ var (param_0, \dots, param_n) \to t \ \texttt{do} \ e & \text{function definition} \\
   &   | & \texttt{fn} \ var (param_0, \dots, param_n)       \ \texttt{do} \ e & \\
\\
param & ::= & p : t & \text{function parameter} \\
      &   | & p     &                           \\ 
\\
lit & ::= & bool   & \text{\texttt{Bool} literal} \\
    &   | & int    & \text{\texttt{Int} literal} \\
    &   | & float  & \text{\texttt{Float} literal} \\
    &   | & char   & \text{\texttt{Char} literal} \\
    &   | & string & \text{\texttt{String} literal} \\
\\
e & ::= & lit                                                                               & \text{literal expression} \\
        &   | & var                                                                         & \text{variable expression} \\
        &   | & (e_0, \dots, e_n)                                                           & \text{tuple expression} \\
        &   | & var \ \{ p_0 : e_0, \dots, p_n : e_n \}                                     & \text{struct expression} \\
        &   | & var :: var \ \{ p_0 : e_0, \dots, p_n : e_n \}                              & \text{enum expression} \\
        &   | & e . var                                                                     & \text{struct field expression} \\
        &   | & e . n                                                                       & \text{tuple field expression} \\
        &   | & \circledast e                                                               & \text{unary operator expression} \\
        &   | & e \circledast e                                                             & \text{binary operator expression} \\
        &   | & e(e_0, \dots, e_n)                                                          & \text{call expression} \\
        &   | & \lambda (param_0, \dots, param_n) \rightarrow e                             & \text{lambda expression} \\
        &   | & \texttt{return} \ e                                                         & \text{return expression} \\
        &   | & \texttt{break} \ e                                                          & \text{break expression} \\
        &   | & \texttt{continue}                                                           & \text{continue expression} \\
        &   | & \texttt{match} \ e \ \{ p_0 \rightarrow e_0, \dots, p_n \rightarrow e_n \}  & \text{match expression} \\
        &   | & \texttt{if} \ e_1 \ \texttt{then} \ e_2 \ \texttt{else} \ e_3               & \text{if-then-else expression} \\
        &   | & \texttt{if} \ e_1 \ \texttt{then} \ e_2                                     & \text{if-then expression} \\
        &   | & \texttt{loop} \ e                                                           & \text{loop expression} \\
        &   | & \{ stmt_0, \dots, stmt_n, e \}                                              & \text{block expression} \\
        &   | & \{ stmt_0, \dots, stmt_n \}                                                 &  \\
\end{array}
$$

