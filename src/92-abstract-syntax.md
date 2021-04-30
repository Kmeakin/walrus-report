## Abstract Syntax of HIR {#sec:appendix:hir}
\newcolumntype{L}{>{$}l<{$}}
\newcolumntype{R}{>{$}r<{$}}
\begin{longtable}{RRLL}
v, var & & & \text{variable} \\
\\
prog & ::= & def_0, \dots, def_n & \text{program}
\\
def & ::= & fn     & \\
    &     & struct & \\
    &     & enum   & \\
\\
fn & ::= & \texttt{fn} \ v (param_0, \dots, param_n) \to t \ \texttt{do} \ e & \text{function definition} \\
   &   | & \texttt{fn} \ v (param_0, \dots, param_n)       \ \texttt{do} \ e &                            \\
\\
struct & ::= & \texttt{struct} \ v \ \{ v_0: t_0, \dots, v_n: t_n \} & \text{struct definition}
\\
enum & ::= & \texttt{enum} \ v \ 
\{ 
v'_0 \ \{ v_0^0: t_0^0, \dots, v_0^{n_0}: t_0^{n_0} \},
\dots,
v'_n \ \{ v_n^0: t_n^0, \dots, v_n^{n_n}: t_n^{n_n} \}
\} & \text{enum definition}
\\
param & ::= & p: t & \text{function parameter} \\
      &   | & p     &                          \\ 
\\
lit & ::= & bool   & \text{Bool literal}   \\
    &   | & int    & \text{Int literal}    \\
    &   | & float  & \text{Float literal}  \\
    &   | & char   & \text{Char literal}   \\
    &   | & string & \text{String literal} \\
\\
expr, e & ::= & lit                                                                   & \text{literal expression}  \\
  &   | & v                                                                           & \text{variable expression} \\
  &   | & (e_0, \dots, e_n)                                                           & \text{tuple expression} \\
  &   | & v \ \{ v_0: e_0, \dots, v_n: e_n \}                                         & \text{struct expression} \\
  &   | & v::v' \ \{ p_0: v_0, \dots, v_n: e_n \}                                     & \text{enum expression} \\
  &   | & e.v                                                                         & \text{struct field expression} \\
  &   | & e.n                                                                         & \text{tuple field expression} \\
  &   | & \circledast \ e                                                             & \text{unary operator expression} \\
  &   | & e_1 \circledast e_2                                                         & \text{binary operator expression} \\
  &   | & e(e_0, \dots, e_n)                                                          & \text{call expression} \\
  &   | & \lambda (param_0, \dots, param_n) \Rightarrow e                             & \text{lambda expression} \\
  &   | & \texttt{if} \ e_1 \ \texttt{then} \ e_2 \ \texttt{else} \ e_3               & \text{if-then-else expression} \\
  &   | & \texttt{if} \ e_1 \ \texttt{then} \ e_2                                     & \text{if-then expression} \\
  &   | & \{ stmt_0, \dots, stmt_n, e \}                                              & \text{block expression} \\
  &   | & \{ stmt_0, \dots, stmt_n \}                                                 &  \\
  &   | & \texttt{match} \ e \ \{ p_0 \Rightarrow e_0, \dots, p_n \Rightarrow e_n \}  & \text{match expression} \\
  &   | & \texttt{loop} \ e                                                           & \text{loop expression} \\
  &   | & \texttt{return} \ e                                                         & \text{return expression} \\
  &   | & \texttt{break} \ e                                                          & \text{break expression} \\
  &   | & \texttt{continue}                                                           & \text{continue expression} \\
\\
op, \circledast & ::= & +, -, !                               & \text{unary operators}  \\
                &   | & +, -, *, /,                           & \text{binary operators} \\
                &   | & \equiv, \nequiv, <, \leq, >, \geq,    &                         \\
                &   | & \land, \lor                           &                         \\
\\
stmt & ::= & e;                           & \text{expression statement}   \\
     &   | & \texttt{let} \ v: t = e;     & \text{let statement}          \\
     &   | & \texttt{let} \ v = e;        &                               \\
\\
pat, p & ::= & lit                                            & \text{literal pattern}    \\
  &   | & v                                                   & \text{variable pattern}   \\
  &   | & \_                                                  & \text{ignored pattern}    \\
  &   | & (p_0, \dots, p_n)                                   & \text{tuple pattern}      \\
  &   | & v \ \{ v_0: p_0, \dots, v_n: p_n \}           & \text{struct pattern}     \\
  &   | & v :: v' \ \{ v_0: p_0, \dots, v_n: p_n \}   & \text{enum pattern}       \\
\\
type, t & ::= & v                   & \text{variable type}      \\
  &   | & \_                        & \text{placeholder type}   \\
  &   | & (t_0, \dots, t_n)         & \text{tuple type}         \\
  &   | & (t_0, \dots, t_n) \to t   & \text{function type}      \\
\end{longtable}

