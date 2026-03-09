---
title: Comments Code Smell

date: 2026-03-08

description: The Comments code smell occurs when comments are used to explain unclear or poorly written code rather than improving the code itself to make it self-explanatory.

---

The Comments code smell does not mean that all comments are bad — it means that comments are being used as a substitute for clear code. When a comment is needed to explain *what* code does or *why* it works the way it does, that is often a signal that the code itself is not expressive enough. Well-written code typically does not require comments to explain its mechanics; the names of methods, variables, and types carry that meaning.

This does not apply to documentation comments (such as XML doc comments or JSDoc) that describe public APIs, or to comments explaining non-obvious business rules or external constraints that cannot be expressed in code. Those serve a legitimate purpose. The smell arises specifically when comments are used to compensate for code that is hard to understand.

## How Comments Become a Code Smell

### Commenting Out Code

Leaving blocks of commented-out code in a codebase is a form of [Dead Code](/code-smells/dead-code/) and a sign that version control is not being trusted. Commented-out code creates noise, raises questions ("Was this removed intentionally? Is it safe to delete?"), and rots over time as surrounding code evolves.

### Explaining What the Code Does

A comment like `// increment counter` above `count++` adds no value. More subtle examples include comments explaining what a complex conditional evaluates to, or what a loop is doing. In both cases, the solution is to extract a well-named method or introduce a well-named variable.

### Flagging Workarounds or TODOs

Comments like `// HACK`, `// TODO`, or `// fix this later` document known problems without resolving them. While sometimes necessary as a short-term measure, these comments accumulate and become permanent fixtures. They are better tracked in an issue tracker where they can be prioritized and addressed.

### Lengthy Method-Level Narration

A method that requires a long comment at the top to explain what it does is almost always a method that should be broken into smaller, better-named methods. The comment is a symptom of a [Long Method](/code-smells/long-method/) that has outgrown a single, clear name.

## Example

Consider this commented code:

```csharp
// Returns true if the user is active and email is confirmed and not suspended
public bool CanLogin(User user)
{
    // Check if user has active status
    if (user.Status != UserStatus.Active)
        return false;
    // Make sure the user's email is confirmed
    if (!user.EmailConfirmed)
        return false;
    // Check that the account is not suspended
    if (user.IsSuspended)
        return false;
    return true;
}
```

The comments are compensating for a lack of expressiveness. The conditions are clear enough on their own, and the method name could carry more meaning:

```csharp
public bool IsEligibleToLogin(User user)
{
    return user.Status == UserStatus.Active
        && user.EmailConfirmed
        && !user.IsSuspended;
}
```

No comments needed — the code expresses its own intent.

## Legitimate Uses of Comments

Not all comments are a smell. Comments are appropriate when:

- Explaining a non-obvious algorithmic choice or performance trade-off.
- Documenting a workaround for a known platform bug, with a reference.
- Providing legal or licensing notices.
- Writing documentation comments for public-facing APIs.
- Explaining *why* a business rule exists when the rule itself cannot be made self-evident.

The test is simple: if removing the comment would leave the code just as understandable, the comment is noise.

## What the Experts Say

A recurring theme across prominent software development literature is that comments are a symptom of failure, not a best practice: As you're about to add a comment, ask yourself, 'How can I improve the code so that this comment isn't needed?' Improve the code and then document it to make it even clearer."
>
> — Steve McConnell, *Code Complete*

> "If the code is so complicated that it needs to be explained, it's nearly always better to improve the code than it is to add comments."
>
> — Steve McConnell, *Code Complete*

> "When you feel the need to write a comment, first try to refactor the code so that any comment becomes superfluous."
>
> — Martin Fowler, *Refactoring: Improving the Design of Existing Code*

> "What of comments that are not technically wrong, but add no value to the code? Such comments are noise. A prevalence of noisy comments and incorrect comments in a code base encourage programmers to ignore all comments… Comment what the code cannot say, not simply what it does not say."
>
> — Kevlin Henney, *97 Things Every Programmer Should Know*

> "A comment is of zero (or negative) value if it is wrong."
>
> — Kernighan and Plauger, *The Elements of Programming Style*

The last point is worth emphasizing: comments can be — and frequently are — wrong. Unlike code, comments are not executed or tested. When code changes and the surrounding comment is not updated, the comment silently diverges from reality. The only way to verify a comment is to read and understand the code, at which point the comment was likely unnecessary anyway.

## Refactoring

- Use **Extract Method** to pull logic into a well-named method, replacing the comment with the method name.
- Use **Introduce Explaining Variable** to name intermediate values that explain a complex expression.
- Use **Rename Method** or **Rename Variable** to make names expressive enough that the comment is redundant.
- Delete commented-out code and trust version control to preserve history.
- Move `// TODO` items to an issue tracker.

## References

- [When To Comment Your Code](https://ardalis.com/when-to-comment-your-code/) by Steve Smith (Ardalis)
- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Long Method](/code-smells/long-method/)
- [Refactoring](/practices/refactoring/)
