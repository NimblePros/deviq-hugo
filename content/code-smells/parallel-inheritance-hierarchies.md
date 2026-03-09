---
title: Parallel Inheritance Hierarchies Code Smell

date: 2026-03-08

description: Parallel Inheritance Hierarchies is a code smell where every time you add a subclass to one class hierarchy, you are forced to add a corresponding subclass to a separate, mirrored hierarchy.

---

Parallel Inheritance Hierarchies is a special case of [Shotgun Surgery](./shotgun-surgery). The smell arises when you have two class hierarchies that must grow in lockstep: every new subclass in one hierarchy requires a matching subclass in the other. The duplication is structural rather than literal — the classes are different, but the hierarchy shape must always be mirrored.

A telltale sign is class names that share significant prefixes: `Dog`, `DogHandler`; `Cat`, `CatHandler`; `Fish`, `FishHandler`. Every time you add an animal, you must add a handler. The compiler does not enforce this pairing — forgetting is easy and consequences appear only at runtime.

## Problems Caused by Parallel Inheritance Hierarchies

### Structural Duplication

The same taxonomy is expressed twice. Every design decision made in one hierarchy must be replicated in the other. When the taxonomy changes — an animal needs a subtype of its own — both hierarchies must be updated in parallel.

### Hidden Coupling

The two hierarchies are tightly coupled, but nothing in the code makes that coupling explicit. A developer unfamiliar with the relationship can add a subclass to one hierarchy and produce a runtime failure or missing behavior without any compile-time warning.

### Fragile Extensibility

What should be a simple extension — adding a new type — becomes a multi-file change. This directly violates the [Open/Closed Principle](/principles/open-closed-principle/): the system should be open for extension without requiring scattered modification.

### Growing Maintenance Burden

The burden compounds with size. A hierarchy with ten subclasses means ten pairs. Adding a new behavior shared by all types means touching at least ten files. Parallel Inheritance Hierarchies age poorly.

## Example

An animal hierarchy with a mirrored training-behavior hierarchy:

```csharp
// First hierarchy: animals
public abstract class Animal
{
    public abstract string Name { get; }
}

public class Dog : Animal
{
    public override string Name => "Dog";
}

public class Cat : Animal
{
    public override string Name => "Cat";
}

// Second hierarchy: mirrors the first
public abstract class AnimalTrainer
{
    public abstract void Train(Animal animal);
}

public class DogTrainer : AnimalTrainer
{
    public override void Train(Animal animal)
        => Console.WriteLine("Teaching dog to sit and fetch.");
}

public class CatTrainer : AnimalTrainer
{
    public override void Train(Animal animal)
        => Console.WriteLine("Teaching cat to use a scratching post.");
}
```

Adding `Fish` requires adding both `Fish` and `FishTrainer`. The pairing is implicit and structurally enforced by convention rather than by design.

After consolidating the behavior into the first hierarchy:

```csharp
public abstract class Animal
{
    public abstract string Name { get; }
    public abstract void Train();
}

public class Dog : Animal
{
    public override string Name => "Dog";
    public override void Train()
        => Console.WriteLine("Teaching dog to sit and fetch.");
}

public class Cat : Animal
{
    public override string Name => "Cat";
    public override void Train()
        => Console.WriteLine("Teaching cat to use a scratching post.");
}
```

Adding `Fish` now requires one class, not two, and the connection between data and behavior is explicit.

When collapsing hierarchies is not appropriate — for example, when the two concerns genuinely belong in separate assemblies — the **Visitor pattern** offers a structured way to add operations across a type hierarchy without mirroring it.

## Addressing Parallel Inheritance Hierarchies

- **Move Method** — relocate methods from the shadow hierarchy into the primary one, so behavior lives alongside the type it describes.
- **Move Field** — similarly consolidate related state.
- **Use the Visitor Pattern** — when the two concerns must remain separate (e.g., domain model vs. persistence layer), the Visitor pattern decouples operations from types without requiring a mirrored hierarchy.
- **Favor composition over inheritance** — rather than mirroring a full hierarchy, inject behavior through interfaces or delegates. Each type carries its own behavior as a dependency rather than inheriting it from a parallel tree.
- **Apply the [Single Responsibility Principle](/principles/single-responsibility-principle/)** — evaluate whether the shadow hierarchy represents a genuinely distinct responsibility. If so, a clean interface and composition may serve better than mirrored inheritance.
