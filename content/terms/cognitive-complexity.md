---
title: Cognitive Complexity

date: 2026-03-09

description: Cognitive complexity is a code metric that measures how difficult a piece of code is to understand, penalizing structural patterns that increase mental effort rather than simply counting decision points.

weight: 30
---

Cognitive complexity is a code metric developed by G. Ann Campbell at SonarSource (published 2018) that attempts to measure how hard a piece of code is for a human to understand, rather than how structurally complex it is. Where [cyclomatic complexity](/terms/cyclomatic-complexity/) counts independent execution paths, cognitive complexity penalizes the patterns that actually make code hard to read — primarily nesting and flow-breaking constructs.

## How It Is Calculated

Cognitive complexity assigns a score to a method based on three types of contributions:

1. **Structural increments** — control flow structures (`if`, `else`, `for`, `while`, `switch`, `catch`, etc.) each add 1 to the score.
2. **Nesting penalties** — each structure nested inside another adds an additional penalty equal to its nesting depth. A deeply nested `if` costs more than a top-level one.
3. **Fundamental increments** — certain constructs that break linear flow (e.g., recursion, sequences of logical operators `&&` / `||`) add to the score without a nesting penalty.

The result is a score that correlates more closely with the human experience of reading code than cyclomatic complexity does.

## Cyclomatic vs. Cognitive Complexity

| Aspect | Cyclomatic Complexity | Cognitive Complexity |
|--------|----------------------|---------------------|
| What it measures | Independent execution paths | Mental effort to understand |
| Nesting sensitivity | None — all branches equal | Heavy — deeper nesting costs more |
| Flat `switch` with many cases | High score | Low score |
| Deeply nested `if` chains | Moderate score | High score |
| Primary use | Estimating test effort | Evaluating readability |

A method can have high cyclomatic complexity but low cognitive complexity — for example, a flat `switch` with twenty cases is easy to read despite having many paths. Conversely, a method with only a few branches can be very hard to read if they are deeply nested. Both metrics together give a more complete picture of the [Conditional Complexity](../code-smells/conditional-complexity) code smell.

## Example

```csharp
// Low cyclomatic, low cognitive — flat and readable
public string Classify(int score) => score switch
{
    >= 90 => "A",
    >= 80 => "B",
    >= 70 => "C",
    >= 60 => "D",
    _     => "F",
};

// Moderate cyclomatic, HIGH cognitive — deeply nested
public string Classify(int score)
{
    if (score >= 60)           // +1
    {
        if (score >= 70)       // +2 (nesting penalty)
        {
            if (score >= 80)   // +3 (nesting penalty)
            {
                if (score >= 90) return "A";  // +4 (nesting penalty)
                return "B";
            }
            return "C";
        }
        return "D";
    }
    return "F";
}
```

The nested version has a lower cyclomatic complexity score than a flat `switch` with the same cases, but a far higher cognitive complexity score — it is harder to read and understand.

## Why Cognitive Complexity Matters

### Readability is the Primary Maintenance Cost

Code is read far more often than it is written. The harder code is to understand, the more time developers spend parsing it, the more likely they are to misunderstand it, and the more likely they are to introduce bugs when changing it.

### Nesting is the Biggest Culprit

Every level of nesting forces the reader to remember more context. Deep nesting is the main driver of high cognitive complexity, and it is also one of the most actionable things to fix with refactoring.

### Complements Cyclomatic Complexity

Using both metrics together surfaces different kinds of problems. Cyclomatic complexity flags methods that need more tests; cognitive complexity flags methods that need to be simplified for readability, even if their path count is manageable.

## Reducing Cognitive Complexity

- **[Guard Clauses](/design-patterns/guard-clause/)** — return or throw early for edge cases to avoid nesting the happy path inside conditions.
- **Extract Method** — pull nested logic into a well-named helper method, replacing nesting with a descriptive call.
- **Replace nested conditionals with polymorphism** — move type-based branches into separate classes, eliminating the nesting entirely.
- **Invert conditions** — change `if (condition) { big block }` to `if (!condition) return;` followed by the block at a lower indent level.
- **Simplify boolean expressions** — introduce named booleans or predicate methods to replace complex `&&`/`||` chains.

## Tooling

Cognitive complexity can be measured automatically:

- **.NET / C#**: SonarAnalyzer for C#, or the [nmbls `cogc` command](https://nmbl.dev/docs/commands/cogc-cognitive-complexity/)
- **JavaScript / TypeScript**: SonarLint, `eslint-plugin-sonarjs`
- **Java / Python / Go**: SonarQube, SonarCloud
- **IDE integration**: SonarLint plugins for Visual Studio, VS Code, IntelliJ IDEA

## References

- *Cognitive Complexity: A new way of measuring understandability* — G. Ann Campbell, SonarSource (2018). The original whitepaper defining the metric.
- [nmbls `cogc` — Cognitive Complexity command](https://nmbl.dev/docs/commands/cogc-cognitive-complexity/)
- [Cyclomatic Complexity](/terms/cyclomatic-complexity/)
- [Aggregate Complexity](/terms/aggregate-complexity/)
- [Conditional Complexity Code Smell](../code-smells/conditional-complexity)
