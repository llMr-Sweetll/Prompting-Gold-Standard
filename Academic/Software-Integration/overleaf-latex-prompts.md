# Overleaf/LaTeX Integration Prompts

Prompts to structure academic writing that compiles cleanly and cites correctly.

## Clean LaTeX Output Policy
```
Output LaTeX only. No comments or explanations. Compile-safe macros only. Use \cite{key} without inventing keys.
```

## Section Scaffolding
```
Task: Create LaTeX sections for a paper on [topic].
Include: \section, \subsection, \label, and placeholder \todo notes.
No content beyond headings and one-sentence scope per section.
```

## Figure and Table Stubs
```
Return LaTeX environments only:
\begin{figure}
  \centering
  % placeholder: [what figure shows]
  \caption{[concise]}
  \label{fig:[name]}
\end{figure}

\begin{table}
  \centering
  \caption{[concise]}
  \label{tab:[name]}
  \begin{tabular}{lll}\toprule
  Col1 & Col2 & Col3 \\\midrule
  ... & ... & ... \\\bottomrule
  \end{tabular}
\end{table}
```

## BibTeX Hydration Plan
```
Given outline topics, output a TODO list of BibTeX entries to fetch (title, venue, year). Do not fabricate. Mark each as [to-collect].
```

