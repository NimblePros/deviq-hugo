---
title: Poor Names Code Smell

date: 2026-03-08

description: The Poor Names code smell occurs when identifiers — variables, methods, classes, and parameters — are named in ways that obscure their purpose, making code harder to read and understand.

---

The Poor Names code smell occurs when the identifiers in code — variables, methods, classes, parameters, and properties — are named in ways that obscure what they represent or what they do. Names are the primary way code communicates intent; a poor name forces the reader to work harder to understand the code, or worse, leads them to a wrong understanding. Good naming is one of the highest-leverage practices in software development, and its absence is a pervasive source of confusion and bugs.

Poor names often arise incrementally. A variable named `x` is acceptable as a loop counter in a tight math expression, but becomes a smell when used to represent a domain concept. A method named `Process` or `Handle` may have been clear at the time it was written but accumulates responsibility over time until the name no longer reflects what the method does.

## Categories of Poor Names

### Abbreviations and Cryptic Identifiers

Names like `cust`, `tmp`, `mgr`, `btn`, or `strVal` force readers to decode abbreviations rather than read meaning directly. Modern IDEs provide autocomplete, making abbreviations unnecessary. Prefer full, descriptive names: `customer`, `temporaryBuffer`, `manager`, `submitButton`, `rawValue`.

### Single-Letter Variables

Single-letter variable names (`a`, `b`, `n`, `x`) outside of conventional contexts (loop indices, mathematical formulas) obscure purpose entirely. A variable holding a list of invoices should be named `invoices`, not `i`.

### Generic or Vague Names

Names like `data`, `info`, `manager`, `processor`, `helper`, `util`, or `service` describe almost nothing. A class named `DataManager` could do anything. These names are often a sign that the abstraction is unclear or that the class is doing too many things.

### Misleading Names

A name that implies something different from what the code actually does is worse than a vague name. A method named `GetUser` that also modifies a record, or a boolean named `isComplete` that is actually `false` when the operation is done, creates incorrect mental models and can directly cause bugs.

### Names That Lie About Type

Using a name that implies a type different from the actual type — for example, `userList` for a dictionary, or `isProcessed` for an integer status code — causes confusion. Names should reflect the nature and type of the value they identify.

### Inconsistent Naming

Using different names for the same concept across a codebase is a signal of the related [Inconsistency](./inconsistency) smell. When the same concept is called `userId`, `user_id`, `UserId`, `uid`, and `id` in different parts of the code, readers must constantly re-verify that these all mean the same thing.

## Example

```csharp
// Poor names
public List<string> GetD(int id, bool f)
{
    var x = _repo.Get(id);
    var res = new List<string>();
    if (f)
    {
        foreach (var i in x.Items)
            res.Add(i.N);
    }
    return res;
}
```

The intent of this method is completely obscured. With meaningful names:

```csharp
public List<string> GetItemNamesForOrder(int orderId, bool includeAll)
{
    var order = _orderRepository.GetById(orderId);
    var itemNames = new List<string>();
    if (includeAll)
    {
        foreach (var item in order.Items)
            itemNames.Add(item.Name);
    }
    return itemNames;
}
```

The code now communicates its intent without needing a single comment.

## Refactoring

- **Rename Variable/Method/Class**: The most direct fix. Use IDE rename refactoring to update all usages safely.
- **Replace Temp with Query**: Replace a poorly-named temporary variable with a well-named method call that makes the intent clear.
- **Extract Method**: If a method's name is vague because it does many things, extract the responsibilities into focused methods with precise names.
- Establish and follow a **naming convention** for the codebase to ensure consistency across the team.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Inconsistency](./inconsistency)
- [Ubiquitous Language](/domain-driven-design/ubiquitous-language/)
- [Refactoring](/practices/refactoring/)
