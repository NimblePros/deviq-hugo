---
title: Flyweight Design Pattern

date: 2026-03-09

description: The Flyweight Design Pattern uses sharing to efficiently support large numbers of fine-grained objects. Learn how to implement the Flyweight pattern in C# to reduce memory usage when working with many similar objects.
weight: 140
---

## What is the Flyweight Design Pattern?

The Flyweight Design Pattern is a structural pattern that uses sharing to efficiently support large numbers of fine-grained objects. Instead of storing all data in every object instance, flyweights separate state into two categories:

- **Intrinsic state** — data that is shared across many objects and does not change based on context (e.g., a tree's species, texture, or color). This is stored inside the flyweight object.
- **Extrinsic state** — data that is unique per instance and depends on context (e.g., a tree's position or scale). This is passed in by the caller rather than stored in the flyweight.

By storing only intrinsic state in shared flyweight objects and passing extrinsic state at call time, the pattern can dramatically reduce memory consumption when your application needs to work with thousands or millions of similar objects.

Common real-world applications include:

- **Game engines** — rendering thousands of trees, particles, or enemies that share the same mesh and texture but have different positions
- **Text editors** — representing each character glyph as a shared object while tracking position and formatting externally
- **UI frameworks** — reusing icon or style objects across many rendered controls

The Flyweight pattern is closely related to the [Proxy](/design-patterns/proxy-pattern/) pattern in that both involve an intermediary object, but Flyweight's purpose is sharing for memory efficiency rather than controlling access. It often works well alongside the [Factory Method](/design-patterns/factory-method-pattern/) or a dedicated factory that manages the cache of shared flyweight instances.

## Intrinsic vs. Extrinsic State

Getting the split right is the key design decision. Ask: "Would this data be identical across many instances in common scenarios?" If yes, it belongs in the flyweight (intrinsic). If it varies per use, pass it as a parameter (extrinsic).

| | Intrinsic | Extrinsic |
|---|---|---|
| Stored in | Flyweight object | Client / context |
| Shared | Yes | No |
| Mutable | No | Yes |
| Example | Tree species, texture | Tree position, scale |

Flyweight objects must be immutable with respect to their intrinsic state. If a shared flyweight's internal data could be changed, one caller's change would silently affect all callers sharing the same instance — a serious bug.

## C# Example

The following example models a forest renderer. A large forest might contain hundreds of thousands of trees, but only a handful of distinct species. Without sharing, each `Tree` object would store its own copy of the species name, texture path, and color, wasting significant memory.

### Flyweight

The `TreeType` class holds all intrinsic state — the data that is the same for every oak, every pine, etc.

```csharp
public class TreeType
{
    public string Species { get; }
    public string TexturePath { get; }
    public string Color { get; }

    public TreeType(string species, string texturePath, string color)
    {
        Species = species;
        TexturePath = texturePath;
        Color = color;
    }

    public void Draw(int x, int y, float scale)
    {
        Console.WriteLine(
            $"Drawing {Species} tree at ({x},{y}) scale={scale:F1} " +
            $"[texture={TexturePath}, color={Color}]");
    }
}
```

### Flyweight Factory

The factory ensures that only one `TreeType` instance exists per unique combination of species, texture, and color.

```csharp
public static class TreeTypeFactory
{
    private static readonly Dictionary<string, TreeType> _cache = new();

    public static TreeType GetTreeType(string species, string texturePath, string color)
    {
        string key = $"{species}|{texturePath}|{color}";

        if (!_cache.TryGetValue(key, out var treeType))
        {
            treeType = new TreeType(species, texturePath, color);
            _cache[key] = treeType;
            Console.WriteLine($"Created new TreeType: {species}");
        }

        return treeType;
    }

    public static int CachedCount => _cache.Count;
}
```

### Context

The `Tree` class holds only extrinsic state — the data unique to this particular tree instance — and delegates rendering to the shared flyweight.

```csharp
public class Tree
{
    private readonly int _x;
    private readonly int _y;
    private readonly float _scale;
    private readonly TreeType _type; // shared flyweight

    public Tree(int x, int y, float scale, TreeType type)
    {
        _x = x;
        _y = y;
        _scale = scale;
        _type = type;
    }

    public void Draw() => _type.Draw(_x, _y, _scale);
}
```

### Usage

```csharp
var forest = new List<Tree>();
var random = new Random(42);

string[] species = ["Oak", "Pine", "Birch"];
string[] colors   = ["DarkGreen", "Green", "LightGreen"];

// Plant 10,000 trees using only 3 shared TreeType flyweights
for (int i = 0; i < 10_000; i++)
{
    int idx = random.Next(species.Length);
    var type = TreeTypeFactory.GetTreeType(
        species[idx],
        $"textures/{species[idx].ToLower()}.png",
        colors[idx]);

    forest.Add(new Tree(
        x: random.Next(1000),
        y: random.Next(1000),
        scale: 0.5f + (float)random.NextDouble(),
        type: type));
}

// Draw the first few trees
foreach (var tree in forest.Take(3))
{
    tree.Draw();
}

Console.WriteLine($"\nTotal trees: {forest.Count}");
Console.WriteLine($"Shared TreeType instances: {TreeTypeFactory.CachedCount}");
```

Output:

```
Created new TreeType: Birch
Created new TreeType: Oak
Created new TreeType: Pine
Drawing Birch tree at (37,849) scale=1.3 [texture=textures/birch.png, color=LightGreen]
Drawing Oak tree at (520,191) scale=0.8 [texture=textures/oak.png, color=DarkGreen]
Drawing Pine tree at (62,718) scale=1.1 [texture=textures/pine.png, color=Green]

Total trees: 10000
Shared TreeType instances: 3
```

Ten thousand `Tree` context objects exist, but only three `TreeType` flyweights are ever allocated. The heavy texture and color data is loaded once and shared across all trees of the same species.

## When to Use the Flyweight Pattern

Apply this pattern when all of the following are true:

1. Your application creates a very large number of objects.
2. Most of those objects share a significant portion of their state.
3. The memory cost or construction overhead of so many objects is causing a measurable problem.

If your object count is small or the shared state is trivial, the Flyweight pattern adds unnecessary complexity without meaningful benefit. Prefer a straightforward design until profiling reveals that object proliferation is an actual bottleneck.

## Intent

Use sharing to efficiently support large numbers of fine-grained objects. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
