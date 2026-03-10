---
title: Vertical Separation Code Smell

date: 2026-03-08

description: The Vertical Separation code smell occurs when related code elements are spread far apart vertically within a file, forcing readers to scroll extensively to understand how code fits together.

weight: 390
---

The Vertical Separation code smell occurs when related pieces of code — a variable and its use, a method and its callers, or a helper and the logic it supports — are placed far apart from each other within a file. Reading and understanding code requires a reader to hold context in their head. When code that belongs together is separated by dozens or hundreds of lines, that context must either be memorized or rebuilt by scrolling back and forth, significantly increasing cognitive load.

This smell is especially common in large classes where convention or habit (such as alphabetical ordering, or grouping by access modifier) scatters related code across the file. It is a companion to the [Regions](./regions) smell: regions are often used specifically to manage the sprawl caused by vertical separation, but they treat the symptom rather than the cause.

## Problems Caused by Vertical Separation

### Increased Cognitive Load

When a variable is declared at the top of a method but not used until fifty lines later, the reader must carry that variable's purpose throughout, even if it is irrelevant to the code in between. The same applies to helper methods placed far from the methods that call them. The reader must jump back and forth to build a complete picture.

### Harder to Review

Code reviews of large files with scattered related logic are harder to perform effectively. Reviewers must scroll extensively or rely on their knowledge of the file's layout to evaluate a change, increasing the chance of missing context.

### Obscures Relationships

When two methods are closely related — one builds data that the other consumes — placing them adjacent makes that relationship obvious. Separating them by a hundred lines of unrelated code hides the relationship entirely.

### Forces Unnecessary Scrolling

Even in isolation, a method or class that forces frequent vertical navigation imposes a shallow but real tax on every reader. Over time, this friction accumulates.

## Example

In a long class ordered alphabetically by method name, related methods end up far apart:

```csharp
public class ReportBuilder
{
    // Line 10
    public void AppendFooter(Report report) { ... }

    // Line 40
    public void AppendHeader(Report report) { ... }

    // Line 80
    public void AppendSection(Report report, string title) { ... }

    // Line 200
    public Report Build() 
    {
        var report = new Report();
        AppendHeader(report);     // defined at line 40
        AppendSection(report, "Summary");  // defined at line 80
        AppendFooter(report);     // defined at line 10
        return report;
    }
}
```

The logical sequence is Build → AppendHeader → AppendSection → AppendFooter, but the methods are in a different order. Placing them in call order makes the code much easier to follow:

```csharp
public class ReportBuilder
{
    public Report Build()
    {
        var report = new Report();
        AppendHeader(report);
        AppendSection(report, "Summary");
        AppendFooter(report);
        return report;
    }

    private void AppendHeader(Report report) { ... }

    private void AppendSection(Report report, string title) { ... }

    private void AppendFooter(Report report) { ... }
}
```

A reader can now follow the call chain from top to bottom without scrolling back up.

## Refactoring

- **Reorder members** so that methods appear near their callers and helpers follow the code that uses them.
- **Declare variables close to their first use**, not at the top of a long method.
- **Extract Class** — if related groups of methods naturally cluster, they may belong in a separate, focused class where they are naturally co-located.
- Remove [Regions](./regions) that enforce artificial groupings and instead order code by logical relationship.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Regions](./regions)
- [Long Method](/code-smells/long-method/)
- [Refactoring](/practices/refactoring/)
