---
title: Model-View-Controller (MVC) Design Pattern

date: 2026-03-09

description: The Model-View-Controller (MVC) pattern separates an application into three components — Model, View, and Controller — to decouple business logic from presentation. Learn how MVC works, how it compares to MVP and MVVM, and why ViewModels often appear inside MVC applications.
---

## What is the MVC Pattern?

Model-View-Controller (MVC) is an architectural pattern that separates an application into three interconnected components:

- **Model** — represents the application's data, business logic, and rules. The model is independent of the UI; it knows nothing about how it is displayed.
- **View** — renders the model's data to the user. In a web application the view is typically an HTML template; in a desktop application it is a window or form. The view should contain minimal logic — only enough to display data.
- **Controller** — handles user input, manipulates the model in response, and selects which view to render. In a web framework the controller maps HTTP requests to actions.

The core benefit is **separation of concerns**: UI rendering logic, business logic, and input handling each live in their own layer and can change independently.

```
User Input ──▶ Controller ──▶ Model
                    │            │
                    └──▶ View ◀──┘
```

MVC originated in Smalltalk-80 in the late 1970s and was popularised on the web by frameworks such as Ruby on Rails, Django, and ASP.NET MVC.

## MVC Participants

### Model

The model encapsulates state and behavior. In a well-structured application the model contains [domain entities](/domain-driven-design/entity/), services, and [repository](/design-patterns/repository-pattern/) abstractions. It has no dependency on the view or controller.

See [Kinds of Models](/terms/kinds-of-models/) for a breakdown of the different model types that commonly appear in MVC applications (domain model, view model, binding model, API model, persistence model).

### View

The view receives a model (or view model — see below) and renders it. In ASP.NET Core MVC this is a Razor `.cshtml` file. The view does not manipulate the model directly; it just displays what it is given.

### Controller

The controller receives an HTTP request, calls the appropriate model/service layer, and returns a view result. A healthy controller is thin — it orchestrates, it does not contain business logic.

```csharp
public class OrdersController : Controller
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    public async Task<IActionResult> Index()
    {
        var orders = await _orderService.GetRecentOrdersAsync();
        var viewModel = orders.Select(o => new OrderSummaryViewModel(o)).ToList();
        return View(viewModel);
    }

    [HttpPost]
    public async Task<IActionResult> Place(PlaceOrderRequest request)
    {
        await _orderService.PlaceOrderAsync(request);
        return RedirectToAction(nameof(Index));
    }
}
```

## ViewModels Inside MVC

The original MVC pattern passes domain model objects directly to the view. In practice this rarely scales well: views often need data aggregated from multiple models, display-only computed properties, or formatting that doesn't belong on a domain entity.

The solution is to introduce a **ViewModel** — a class shaped precisely to what a specific view needs:

```csharp
public class OrderSummaryViewModel
{
    public int OrderId { get; init; }
    public string CustomerName { get; init; } = "";
    public string StatusDisplay { get; init; } = "";
    public decimal Total { get; init; }
    public string TotalFormatted => Total.ToString("C");
}
```

The controller maps from the domain model to the view model before passing it to the view. This keeps the domain model clean, prevents views from depending on persistence-level concerns, and gives each view exactly the shape of data it needs.

This is sometimes called the **MVC + ViewModel** approach. It is so common — especially in ASP.NET MVC / ASP.NET Core — that ViewModels are virtually always present in production MVC web applications. See the [REPR Design Pattern](/design-patterns/repr-design-pattern/) for discussion of how even this adaptation struggles for API-only scenarios.

## MVC vs. MVP vs. MVVM

MVC is one of a family of closely related patterns. All three separate model from presentation, but they differ in *how* the three parts communicate and where logic lives.

### Model-View-Presenter (MVP)

MVP replaces the controller with a **Presenter** that has a direct, two-way relationship with the View via an interface:

| Aspect | MVC | MVP |
|---|---|---|
| View awareness | View is passive; controller selects it | View and Presenter communicate through an interface |
| Testability | Controller is testable; view is harder | Presenter is fully testable via the view interface |
| Coupling | Controller does not hold a reference to a specific view instance | Presenter holds a reference to the view interface |

MVP is common in WinForms, Android (pre-Architecture Components), and other frameworks where the view is a concrete object the presenter can poke directly. The Presenter can fully test the presentation logic because all view interaction goes through an interface.

### Model-View-ViewModel (MVVM)

MVVM replaces the controller with a **ViewModel** that exposes observable properties and commands. The View *data-binds* to the ViewModel; no imperative code in the ViewModel needs to know the View exists.

| Aspect | MVC | MVVM |
|---|---|---|
| View update mechanism | Controller explicitly selects/renders the view | Data binding — view automatically reflects ViewModel state |
| ViewModel role | Optional presentation-shaping DTO | Core participant; exposes commands and observable state |
| Typical platforms | Web (server-rendered), REST APIs | WPF, WinUI, MAUI, Blazor, Angular, Vue |

MVVM is the dominant pattern on data-binding-rich platforms. The ViewModel knows nothing about the View; the View observes the ViewModel through the platform's binding engine.

### Summary

| | MVC | MVP | MVVM |
|---|---|---|---|
| Mediator between Model and View | Controller | Presenter | ViewModel |
| View updates | Controller pushes | Presenter pushes via interface | Binding pulls automatically |
| Testability of UI logic | Medium | High (via view interface mocks) | High (ViewModel has no UI deps) |
| Best suited for | Server-rendered web, REST | Traditional desktop/mobile | Data-binding platforms |

In practice the lines blur — many real-world ASP.NET Core applications use MVC structure with ViewModels almost to the point of MVVM on the front end, and Razor Pages in ASP.NET Core is closer to MVP than MVC.

## Intent

Separate the concerns of data (Model), presentation (View), and input handling (Controller) so that each can be developed and tested independently.

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

[ASP.NET Core MVC Overview](https://learn.microsoft.com/en-us/aspnet/core/mvc/overview)

[Kinds of Models](/terms/kinds-of-models/)
