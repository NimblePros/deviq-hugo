---
title: Interpreter Design Pattern

date: 2026-03-09

description: The Interpreter Design Pattern defines a grammar for a language and provides an interpreter to process sentences in that language. Learn how to implement the Interpreter pattern in C# using abstract syntax trees.
---

## What is the Interpreter Design Pattern?

The Interpreter Design Pattern is a behavioral pattern that defines a representation for a grammar along with an interpreter that uses that representation to evaluate sentences in the language. Each rule in the grammar maps to a class, and a sentence in the language is represented as a tree of those objects — called an *abstract syntax tree* (AST).

This pattern is well suited to problems where:

- You have a simple, well-defined grammar that needs to be evaluated repeatedly with different inputs.
- The grammar is stable and unlikely to grow substantially over time.
- You want to represent expressions as composable, first-class objects rather than hard-coded logic.

Common real-world applications include:

- **Rule or permission engines** — evaluating conditions like `"Admin AND Active"` against a runtime context
- **Configuration DSLs** — processing simple domain-specific query or filter syntax
- **Mathematical expression evaluators** — parsing and computing formulas at runtime
- **Template engines** — interpreting placeholder expressions in text templates

The pattern defines four roles:

- **AbstractExpression** — declares the `Interpret` operation that all grammar elements must implement.
- **TerminalExpression** — handles the base cases of the grammar (variables, literals). It has no children.
- **NonterminalExpression** — handles composite grammar rules (AND, OR, NOT). It holds references to child expressions and recursively delegates to them.
- **Context** — carries the global state needed during interpretation (e.g., variable values).

## Relationship to Other Patterns

The AST produced by the Interpreter pattern is structurally a [Composite](/design-patterns/composite-pattern/): terminal expressions are the leaves and nonterminal expressions are the composites. If you need to add new *operations* over an existing AST — such as pretty-printing, optimization, or type-checking — without modifying the expression classes, the [Visitor](/design-patterns/visitor-pattern/) pattern is a natural companion. The [Iterator](/design-patterns/iterator-pattern/) pattern is commonly used to traverse the nodes of the AST in a specific order (for example, walking a token stream during parsing).

Because each grammar rule is a separate class, Interpreter follows the [Single Responsibility Principle](/principles/single-responsibility-principle/) and the [Open-Closed Principle](/principles/open-closed-principle/): new grammar rules can be added by introducing new expression classes rather than by modifying existing ones.

## C# Example

The following example evaluates boolean permission expressions against a runtime context. An expression such as `(Admin OR VIP) AND Active` is built as an AST and evaluated against a dictionary of named boolean flags.

### Context

```csharp
public class Context
{
    private readonly Dictionary<string, bool> _variables;

    public Context(Dictionary<string, bool> variables)
    {
        _variables = variables;
    }

    public bool Lookup(string name)
    {
        if (_variables.TryGetValue(name, out bool value))
            return value;

        throw new KeyNotFoundException($"Variable '{name}' not found in context.");
    }
}
```

### Abstract Expression

```csharp
public interface IBooleanExpression
{
    bool Interpret(Context context);
}
```

### Terminal Expression

`VariableExpression` is a leaf node. It looks up a named flag in the context.

```csharp
public class VariableExpression : IBooleanExpression
{
    private readonly string _name;

    public VariableExpression(string name)
    {
        _name = name;
    }

    public bool Interpret(Context context) => context.Lookup(_name);
}
```

### Nonterminal Expressions

Each nonterminal expression holds one or two child expressions and delegates to them recursively.

```csharp
public class AndExpression : IBooleanExpression
{
    private readonly IBooleanExpression _left;
    private readonly IBooleanExpression _right;

    public AndExpression(IBooleanExpression left, IBooleanExpression right)
    {
        _left = left;
        _right = right;
    }

    public bool Interpret(Context context) =>
        _left.Interpret(context) && _right.Interpret(context);
}

public class OrExpression : IBooleanExpression
{
    private readonly IBooleanExpression _left;
    private readonly IBooleanExpression _right;

    public OrExpression(IBooleanExpression left, IBooleanExpression right)
    {
        _left = left;
        _right = right;
    }

    public bool Interpret(Context context) =>
        _left.Interpret(context) || _right.Interpret(context);
}

public class NotExpression : IBooleanExpression
{
    private readonly IBooleanExpression _operand;

    public NotExpression(IBooleanExpression operand)
    {
        _operand = operand;
    }

    public bool Interpret(Context context) => !_operand.Interpret(context);
}
```

### Usage

```csharp
// AST for: (Admin OR VIP) AND Active
IBooleanExpression rule = new AndExpression(
    new OrExpression(
        new VariableExpression("Admin"),
        new VariableExpression("VIP")),
    new VariableExpression("Active"));

var adminActive = new Context(new Dictionary<string, bool>
{
    ["Admin"]  = true,
    ["VIP"]    = false,
    ["Active"] = true
});

var vipInactive = new Context(new Dictionary<string, bool>
{
    ["Admin"]  = false,
    ["VIP"]    = true,
    ["Active"] = false
});

var regularUser = new Context(new Dictionary<string, bool>
{
    ["Admin"]  = false,
    ["VIP"]    = false,
    ["Active"] = true
});

Console.WriteLine($"Admin (active):   {rule.Interpret(adminActive)}");   // True
Console.WriteLine($"VIP (inactive):   {rule.Interpret(vipInactive)}");   // False
Console.WriteLine($"Regular (active): {rule.Interpret(regularUser)}");   // False
```

Output:

```
Admin (active):   True
VIP (inactive):   False
Regular (active): False
```

The same AST is evaluated against different contexts without rebuilding or recompiling anything. New grammar elements — such as an `XorExpression` or a `LiteralExpression` for constants — can be added by implementing `IBooleanExpression` with no changes to existing code.

## When to Use the Interpreter Pattern

The Interpreter pattern is most appropriate when:

- The grammar is **simple**. Each rule becomes a class, so a large grammar produces a large number of classes that can become difficult to manage and maintain.
- **Efficiency is not the primary concern**. Recursive AST traversal is convenient but not optimized. For performance-sensitive parsing, consider a dedicated parser library or code generation approach.
- **Composability matters**. If you need to construct, combine, and reuse expressions programmatically — such as building access rules from configuration — the object-per-rule structure is a natural fit.

For complex grammars, tools such as ANTLR or parser combinators are generally a better choice than hand-writing an Interpreter implementation.

## Intent

Given a language, define a representation for its grammar along with an interpreter that uses the representation to interpret sentences in the language. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
