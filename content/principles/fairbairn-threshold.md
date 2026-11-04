---
title: Fairbairn Threshold
date: 2026-11-03
description: The Fairbairn Threshold is the point at which the effort of looking up or keeping track of a definition is outweighed by the effort of rederiving it or inlining it. Use it to decide when a tiny helper deserves a name.
params:
  image: /principles/images/fairbairn-threshold.png
weight: 75
---

![fairbairn threshold](./images/fairbairn-threshold.png)

_"The Fairbairn threshold is the point at which the effort of looking up or keeping track of the definition is outweighed by the effort of rederiving it or inlining it."_ — Edward Kmett

The Fairbairn Threshold is a rule of thumb for deciding whether a small piece of behavior deserves its own name. Every named function, method, or helper carries a cost: someone has to discover it, remember it exists, recall exactly what it does, and trust that it does what its name suggests. When the code behind the name is so short and obvious that a developer could simply write it out in less time than it takes to find and verify the helper, the name is below the threshold. It adds to the vocabulary of a codebase without adding any real capability.

## Table of Contents

- [Origin](#origin)
- [Why It Matters](#why-it-matters)
- [A C# Example](#a-c-example)
- [Exceptions to the Rule](#exceptions-to-the-rule)
- [Tension with Don't Repeat Yourself](#tension-with-dont-repeat-yourself)
- [Micro-Dependencies](#micro-dependencies)
- [See Also](#see-also)
- [References](#references)

## Origin

The term comes from the Haskell community and is named after Jón Fairbairn, one of the original members of the Haskell committee. In October 2006, a discussion on the Haskell libraries mailing list debated what to call a proposed `Data.List` function that joins a list of lists with a separator. Fairbairn replied under the subject line _"Names for small functions: just say no..."_, arguing that a function whose definition is as short as `(concat.).intersperse` might be better left unnamed, since everything involved is something a Haskell programmer has to learn anyway, and if the usage is frequent it will become idiomatic. The HaskellWiki notes that this argument may have originated the term.

The most widely cited definition comes from Edward Kmett, writing on the same mailing list in 2012 and quoted on the HaskellWiki page. He describes the threshold's primary use as _"a litmus test to avoid giving names to trivial compositions"_, and gives a concrete test: any function whose definition isn't much longer than its name, such as `fooBar = foo . bar`, falls below the threshold.

## Why It Matters

Although it was coined to keep Haskell's standard libraries lean, the Fairbairn Threshold applies to any codebase that accumulates helpers, utilities, and extension methods.

### Names Are Not Free

A name is a promise that the reader can understand a call site without reading the implementation. That promise only holds if the reader already knows what the name means. For a trivial helper, the first encounter forces a detour: navigate to the definition, read it, confirm there are no surprises, and navigate back. That detour costs more than reading the one-line expression it replaced. Naming is hard enough already (see [Naming Things](/practices/naming-things/)) without spending the effort on names that don't earn their keep.

### Combinations Explode

Kmett points out that given _n_ combinators, there are roughly _O(n²)_ ways to combine just two of them. Naming every useful pairing produces a much larger library with no real increase in utility, and a much higher cognitive overhead to track all the combinations. This is the same multiplicative growth described by the [Combinatorial Explosion](/code-smells/combinatorial-explosion/) code smell, applied to an API surface rather than a class hierarchy.

### Composition Over Memorization

Kmett also observes that the existence of some prebuilt combinations tends to send developers looking for ever larger ones, rather than learning to compose the simple pieces themselves. A small set of general-purpose building blocks that developers know well is easier to work with than a large catalog of narrow helpers that each have to be looked up. Keeping the vocabulary small reduces [cognitive complexity](/metrics/cognitive-complexity/) and supports [Keep It Simple](/principles/keep-it-simple/).

## A C# Example

Most long-lived C# codebases have a `StringExtensions` or `EnumerableExtensions` class that has grown one tiny method at a time:

```csharp
public static class StringExtensions
{
    // Each of these is barely longer than its name.
    public static string TrimAndLower(this string value) => value.Trim().ToLowerInvariant();

    public static string TrimAndUpper(this string value) => value.Trim().ToUpperInvariant();

    public static bool IsBlank(this string? value) => string.IsNullOrWhiteSpace(value);

    public static bool IsNotBlank(this string? value) => !string.IsNullOrWhiteSpace(value);
}
```

At the call site, a reader must stop and check what these do:

```csharp
// Does TrimAndLower trim both ends? Does IsNotBlank treat whitespace-only strings as blank?
var key = input.TrimAndLower();
if (customer.Email.IsNotBlank()) { /* ... */ }
```

None of these helpers are wrong, but every one is below the Fairbairn Threshold. The inlined versions are just as short, use APIs every C# developer already knows, and leave nothing to look up:

```csharp
var key = input.Trim().ToLowerInvariant();
if (!string.IsNullOrWhiteSpace(customer.Email)) { /* ... */ }
```

Compare that to a helper that names a _decision_ rather than a _mechanism_:

```csharp
public static class OrderRules
{
    public static bool QualifiesForFreeShipping(Order order) =>
        order.Subtotal >= 50m && order.ShippingAddress.Country == "US" && !order.ContainsOversizedItems;
}
```

This method is not much longer than the trivial helpers above, but it sits comfortably above the threshold. The name tells the reader something they could not have rederived from first principles, namely the business rule, and it gives that rule a single place to change. The question is not "how many characters does this save?" but "would a reader rather look this up or just read it?"

## Exceptions to the Rule

Kmett is explicit that there are reasonable exceptions for especially common idioms; the threshold is a rule of thumb, not a law. A name can be worth having even for a one-liner when:

- **The idiom is ubiquitous.** If a combination appears constantly and the team already knows it by name, the name is cheap to keep track of. The `Data.List` function from Fairbairn's original thread was in fact eventually named [`intercalate`](https://hackage.haskell.org/package/base/docs/Data-List.html#v:intercalate).
- **The name captures domain knowledge**, as in `QualifiesForFreeShipping` above.
- **The inlined form is easy to get subtly wrong**, such as culture-sensitive string comparisons or off-by-one boundary checks. A name that encodes the correct choice prevents a class of bugs.
- **The name is the extension point.** If the behavior is expected to vary, a seam with a name may be justified. Be careful, though, that this isn't [Speculative Generality](/code-smells/speculative-generality/) in disguise, or a case of [YAGNI](/principles/yagni/).

## Tension with Don't Repeat Yourself

At first glance the Fairbairn Threshold seems to contradict [Don't Repeat Yourself](/principles/dont-repeat-yourself/) (DRY). If `value.Trim().ToLowerInvariant()` appears in twenty places, isn't that [duplicate code](/code-smells/duplicate-code/)?

Usually not in the sense that matters. DRY and [Once and Only Once](/principles/once-and-only-once/) are about duplicated _knowledge_: business rules, decisions, and behavior that must change together. Repeating a short composition of well-known primitives is closer to repeating a common phrase in English than to duplicating a policy. If all twenty call sites represent the same rule ("we normalize customer keys this way"), then the rule deserves a name that says so, like `NormalizeCustomerKey`, and DRY wins. If they are twenty unrelated places that happen to want trimmed, lowercase text, a shared helper couples them for no benefit and the Fairbairn Threshold wins.

Over-applying DRY to trivial expressions tends to produce thin wrappers that exist only to delegate, a smaller-scale relative of the [Middle Man](/code-smells/middle-man/) and [Class Doesn't Do Much](/code-smells/class-doesnt-do-much/) smells.

## Micro-Dependencies

The threshold applies to package dependencies as much as to helper methods. The best-known cautionary tale is the 2016 `left-pad` incident, in which an 11-line npm package that pads the start of a string was unpublished, and thousands of projects that depended on it, directly or transitively, including Babel and React, failed to build or install until npm restored it.

A dependency is a name you have to keep track of with a lot of extra baggage: a version, a maintainer, a license, a supply chain, and a build that breaks if it disappears. For something as small as left-padding a string, inlining the logic (or using a built-in like JavaScript's `String.prototype.padStart` or .NET's `string.PadLeft`) is almost always cheaper. That doesn't mean you should [reinvent the wheel](/antipatterns/reinventing-the-wheel/) for substantial functionality, but a wheel is not the same thing as a lug nut.

> **A note on irony:** The definition of the Fairbairn Threshold fits in a single sentence, barely longer than its name. By its own logic, it probably wasn't worth looking up, and it certainly isn't worth remembering. If you've made it this far, it's too late to get those minutes back. Feel free to forget the whole thing by the next heading; you can always rederive it.

## See Also

- [Don't Repeat Yourself](/principles/dont-repeat-yourself/)
- [Once and Only Once](/principles/once-and-only-once/)
- [Keep It Simple](/principles/keep-it-simple/)
- [YAGNI](/principles/yagni/)
- [Naming Things](/practices/naming-things/)
- [Cognitive Complexity](/metrics/cognitive-complexity/)
- [Combinatorial Explosion](/code-smells/combinatorial-explosion/)
- [Speculative Generality](/code-smells/speculative-generality/)
- [Middle Man](/code-smells/middle-man/)
- [Reinventing the Wheel](/antipatterns/reinventing-the-wheel/)

## References

[Fairbairn threshold](https://wiki.haskell.org/Fairbairn_threshold) on the HaskellWiki

Jon Fairbairn, [Names for small functions: just say no... Re: Data.List.join](https://mail.haskell.org/pipermail/libraries/2006-October/005959.html), Haskell libraries mailing list, October 23, 2006

Edward Kmett, [Re: generalization of maybeToList](https://mail.haskell.org/pipermail/libraries/2012-February/017548.html), Haskell libraries mailing list, February 15, 2012

[npm left-pad incident](https://en.wikipedia.org/wiki/Npm_left-pad_incident) on Wikipedia
