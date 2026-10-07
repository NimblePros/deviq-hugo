---
title: Data Transfer Object (DTO) Pattern
date: 2026-10-07
description: A Data Transfer Object (DTO) is a simple object that carries data between processes or layers of an application. It has no behavior, and it keeps your domain model decoupled from the shape of your data on the wire.
params:
  image: /design-patterns/images/data-transfer-object-pattern.png
weight: 85
---

![Data Transfer Object (DTO)](./images/data-transfer-object-pattern.png)

A _Data Transfer Object_ (DTO) is an object whose only job is to carry data from one place to another, such as between a server and a client, or between layers of an application. A DTO is about data, not behavior: it holds values and nothing else, with no business rules, no validation logic, and no instance methods.

## Origin

Martin Fowler described the DTO pattern in _Patterns of Enterprise Application Architecture_ (PoEAA). His motivation was remote calls. Each call to a remote interface is expensive, so it is better to fetch or send all the data you need in a single call than to make many fine-grained calls. A DTO bundles that data into one object that can be serialized, sent across the wire, and deserialized on the other side. The DTO also keeps the remote interface independent of the internal structure of the objects behind it.

Although the original driver was reducing the number of remote calls, the pattern is used today mostly for its decoupling benefits.

## Common Uses

Think of a DTO as a _message_: a package of data sent from one part of a system to another. Depending on where it is used, it goes by several names.

- **API requests and responses (API models).** DTOs define the contract of a web API. Clients depend on the DTO shape, not on your internal classes.
- **View models.** In an MVC application, a view model is a DTO with an intention-revealing name that contains the data a view needs. Not every MVC view model is a DTO, but many can and should be. See [Kinds of Models](/terms/kinds-of-models/).
- **Binding models.** Types used for model binding that accept only the fields a form or request is allowed to submit.
- **Messages.** Commands, events, and queue messages are typically simple data containers that are serialized between services.
- **Decoupling the domain model from the wire format.** The domain model can evolve (rename properties, restructure entities, add behavior) without breaking clients, as long as the mapping to the DTO is updated.

View models in the Model-View-ViewModel (MVVM) pattern are different. They typically contain a lot of behavior, so they are not DTOs.

## DTOs Have No Behavior

By definition, a DTO contains only data. If a type contains logic, it is not a DTO. That logic belongs in the [domain model](/domain-driven-design/anemic-model/) or in services.

There is also a practical reason. A DTO usually exists as a serialized string (JSON, XML) that crosses a process boundary, and behavior does not exist in that representation. If a property setter enforces that only valid values are accepted, data from an external source that does not follow those constraints can break deserialization. The same is true of a type without a default public constructor, which many serializers cannot instantiate.

A DTO should also be a plain object (a POCO in .NET): no special base classes, no dependencies on frameworks, and no static calls that couple it to behavior. All DTOs are POCOs, but not all POCOs are DTOs. An entity with private setters and methods is a POCO, but it is not a DTO.

### Public Properties and Constructors

Because a DTO has no behavior and no hidden state, [encapsulation](/principles/encapsulation/) offers it little. Encapsulation protects invariants, and a DTO has none. The classic guidance is to give a DTO a public parameterless constructor and public getters and setters for every property, so it is trivial to create, read, write, and serialize.

### Should DTOs Be Immutable?

Immutability has real benefits, and it is not wrong for DTOs. Modern C# records give you concise, immutable-by-default DTOs with value-based equality, and records with positional constructors serialize and deserialize fine with `System.Text.Json`. So the classic approach (a class with a parameterless constructor and public get/set) and a record both work. The classic guidance dates from before records existed, and the two are in some tension, so choose one style, apply it consistently, and make sure your serializer round-trips it without custom work. What matters is that the DTO is easy to create and easy to read, and that it contains no behavior.

### Should DTOs Be Tested?

A DTO with no logic has nothing to unit test. Testing getters and setters adds noise without value. Test the things around DTOs instead: the mapping code that creates them, and serialization round-trips when the wire format is a published contract. If you find yourself wanting to write unit tests for a DTO, it probably contains logic that should live somewhere else.

## Mapping and Factories

You need code that converts between entities and DTOs. Consolidate that mapping in one place rather than scattering it across controllers and services. A common approach is a static factory method on the DTO, conventionally named with a `From` prefix.

```csharp
public class CustomerDto
{
  public string FirstName { get; set; } = string.Empty;
  public string LastName { get; set; } = string.Empty;

  // A static helper kept here for organization. It adds no behavior
  // to a DTO instance, so the DTO is still just data.
  public static CustomerDto FromCustomer(Customer customer)
  {
    return new CustomerDto
    {
      FirstName = customer.FirstName,
      LastName = customer.LastName
    };
  }
}
```

A static factory is not behavior added to the DTO; it is a static method that happens to live next to the type it creates. If you prefer to keep DTOs completely free of references to entities, an extension method in a separate mapping class works too.

Once you have more than a couple of factory methods, consider moving to a mapping library such as AutoMapper to reduce the repetitive code. Explicit factories are simple and easy to debug, and a library pays off as the number of mappings grows. Pick the option whose cost fits your project.

## Example

The following example shows a domain entity, response and request DTOs, and an endpoint that uses them.

```csharp
// Domain entity: has behavior and protects its invariants
public class Product
{
  public int Id { get; private set; }
  public string Name { get; private set; }
  public decimal Price { get; private set; }
  public string? InternalCostCode { get; private set; } // never exposed

  public Product(string name, decimal price)
  {
    Name = name;
    ChangePrice(price);
  }

  public void ChangePrice(decimal price)
  {
    if (price < 0) throw new ArgumentOutOfRangeException(nameof(price));
    Price = price;
  }
}

// Response DTO: data only, with a static factory for mapping
public record ProductDto(int Id, string Name, decimal Price)
{
  public static ProductDto FromProduct(Product product) =>
    new(product.Id, product.Name, product.Price);
}

// Request DTO: only the fields a client may submit
public record CreateProductRequest(
  [property: Required] string Name,
  [property: Range(0, double.MaxValue)] decimal Price);

// Endpoint
app.MapPost("/products", async (CreateProductRequest request, IRepository<Product> repo) =>
{
  var product = new Product(request.Name, request.Price);
  await repo.AddAsync(product);
  return Results.Created($"/products/{product.Id}", ProductDto.FromProduct(product));
});
```

The client never sees `InternalCostCode`, and the entity can change shape without changing the API contract.

## Attributes and Validation

Adding attributes such as `[Required]` or `[Range]` (DataAnnotations) to a DTO is perfectly reasonable. They add no behavior to the DTO itself. They describe constraints that the model binding infrastructure enforces. If attributes start to cause pain, for example because validation rules get complex or depend on context, reconsider them, following [Pain Driven Development](/practices/pain-driven-development/). A common alternative is a validation library such as [FluentValidation](https://docs.fluentvalidation.net/), which keeps rules outside the DTO.

## Keeping DTOs Pure

Avoid referencing non-DTO or non-primitive types, such as entities, from your DTOs. Doing so pulls in dependencies, makes the DTO harder to secure, and can introduce vulnerabilities. In particular, if you bind an entity (or a DTO that exposes one) directly from external input, an attacker can guess the structure of the entity and its navigation properties and update data outside the intended bounds. This is called _over-posting_. Instead, accept a DTO that contains only the fields a client may change, and update only those specific fields on the entity. Never model-bind an entity from external input and save it.

## Dos and Don'ts

- **Don't** hide the default constructor.
- **Do** make properties available through a public getter and setter.
- **Don't** validate inputs to a DTO.
- **Don't** add instance methods.
- **Do** consolidate mapping logic into static factory methods.
- **Do** consider moving to AutoMapper (or a similar tool) if you have more than a few factory methods.
- **Do** feel free to use attributes for model validation.
- **Don't** reference non-DTO types, such as entities, from DTOs.

The first two items reflect the classic guidance. If you choose records with positional constructors, make sure your serializer handles them, as `System.Text.Json` does.

## Common Pitfalls

- **Exposing domain entities directly.** Returning entities from an API couples clients to your internal model and risks leaking data. Binding them from requests invites over-posting, and serializing navigation properties can cause cycles.
- **Putting logic in DTOs.** Once a DTO has behavior, it is no longer a DTO, and it becomes a second place where business rules live. If the domain model ends up with no behavior because it all moved elsewhere, you have an [anemic model](/domain-driven-design/anemic-model/).
- **Mapping overhead.** Every DTO needs mapping code, and it must be kept in sync. For simple CRUD apps with trivial models, this can be more ceremony than benefit. Apply [YAGNI](/principles/yagni/) and add DTOs where decoupling is worth the cost.
- **Over-reusing one DTO.** Using the same DTO for create, update, and read operations leads to properties that are required in some cases and meaningless in others. Separate request and response types are cheap and clearer.
- **Vague names.** A name like `FooDTO` says nothing about where it is used. Prefer names that reveal intent, such as `FooViewModel`, `CreateFooRequest`, or `FooResponse`.

## See Also

[Kinds of Models](/terms/kinds-of-models/)

[Anemic Model](/domain-driven-design/anemic-model/)

[Encapsulation](/principles/encapsulation/)

[Separation of Concerns](/principles/separation-of-concerns/)

[Persistence Ignorance](/principles/persistence-ignorance/)

[Pain Driven Development](/practices/pain-driven-development/)

## References

- [Weekly Dev Tips: Data Transfer Objects (Part 1)](https://weeklydevtips.com/episodes/008-d2a763a5)
- [Weekly Dev Tips: Data Transfer Objects (Part 2)](https://weeklydevtips.com/episodes/009-cde0c1e7)
- [5 Rules For DTOs (YouTube)](https://www.youtube.com/watch?v=W4n9x_qGpT4)
- [What is the difference between a DTO and a POCO (or POJO)?](https://ardalis.com/dto-or-poco/)
- [Web API DTO Considerations](https://ardalis.com/web-api-dto-considerations/)
- Martin Fowler, [Data Transfer Object](https://martinfowler.com/eaaCatalog/dataTransferObject.html), _Patterns of Enterprise Application Architecture_
