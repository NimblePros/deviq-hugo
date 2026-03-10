---
title: Model-View-Presenter (MVP) Design Pattern

date: 2026-03-09

description: The Model-View-Presenter (MVP) pattern separates UI logic from the view by introducing a Presenter that communicates with the View through an interface, making presentation logic fully unit-testable. Learn how MVP works, its two variants, and how it compares to MVC and MVVM.
---

## What is the MVP Pattern?

Model-View-Presenter (MVP) is an architectural pattern derived from [MVC](/design-patterns/mvc-pattern/) that separates an application into three components:

- **Model** — represents data, business logic, and rules. The model is entirely independent of the UI.
- **View** — displays data and forwards user input to the Presenter. In MVP the view is intentionally *passive* — it contains no logic of its own, only rendering and delegation.
- **Presenter** — mediates between Model and View. It retrieves data from the model, formats it for display, and pushes it to the view. It also handles all user input events forwarded by the view.

The defining structural difference from MVC is that **the Presenter holds a direct reference to the View through an interface**. This makes the entire presenter — including all presentation logic that in MVC would be scattered across controllers and views — fully testable without a UI framework.

```
User Input ──▶ View ──▶ Presenter ──▶ Model
                 ◀──────────┘
                 (via IView interface)
```

MVP originated at Taligent in the 1990s and was popularised by Martin Fowler's refinement into the *Supervising Controller* and *Passive View* variants.

## MVP Participants

### Model

The same as in MVC: domain entities, services, repositories. The model has no knowledge of the view or presenter.

### View (Passive View)

The view in MVP is deliberately kept dumb. It exposes only:

- Properties for each piece of data it displays (the presenter sets them).
- Events or method calls that notify the presenter of user actions.

The view implements an `IView` interface that the presenter depends on. This is what enables the presenter to be tested in isolation — a test can supply a fake view.

```csharp
public interface IOrderListView
{
    IReadOnlyList<OrderSummary> Orders { set; }
    string StatusMessage { set; }
    event EventHandler RefreshRequested;
}
```

### Presenter

The presenter holds a reference to the `IView` interface and to the model/service layer. It subscribes to view events and pushes data back to the view.

```csharp
public class OrderListPresenter
{
    private readonly IOrderListView _view;
    private readonly IOrderService _orderService;

    public OrderListPresenter(IOrderListView view, IOrderService orderService)
    {
        _view = view;
        _orderService = orderService;
        _view.RefreshRequested += OnRefreshRequested;
    }

    public void Initialize()
    {
        LoadOrders();
    }

    private async void OnRefreshRequested(object? sender, EventArgs e)
    {
        LoadOrders();
    }

    private async void LoadOrders()
    {
        var orders = await _orderService.GetRecentOrdersAsync();
        _view.Orders = orders;
        _view.StatusMessage = $"{orders.Count} orders loaded.";
    }
}
```

### The Concrete View

The concrete view (a WinForms form, a web page code-behind, a Razor Page, etc.) implements `IView`, wires up event handlers, and sets properties:

```csharp
public partial class OrderListForm : Form, IOrderListView
{
    private readonly OrderListPresenter _presenter;

    public OrderListForm(IOrderService orderService)
    {
        InitializeComponent();
        _presenter = new OrderListPresenter(this, orderService);
        btnRefresh.Click += (s, e) => RefreshRequested?.Invoke(this, EventArgs.Empty);
        Load += (s, e) => _presenter.Initialize();
    }

    public IReadOnlyList<OrderSummary> Orders
    {
        set => orderGrid.DataSource = value;
    }

    public string StatusMessage
    {
        set => lblStatus.Text = value;
    }

    public event EventHandler? RefreshRequested;
}
```

## Two Variants: Passive View vs. Supervising Controller

Martin Fowler identified two flavours of MVP:

### Passive View

The view is completely inert — all logic lives in the presenter. The view exposes only primitive setters and events. The presenter reads from the model and writes every individual property of the view. This maximises testability: you can test *all* presentation behaviour through the presenter alone.

### Supervising Controller

The view retains simple data-binding to the model for straightforward display tasks, while the presenter handles only complex logic that plain binding cannot express. This reduces boilerplate at the cost of some testability — some behaviour lives in the binding and is harder to test independently.

Most modern guidance favours Passive View because it draws a clean line: the presenter is fully testable, the view is a thin rendering shell.

## Testing the Presenter

Because the presenter depends on `IView` and `IOrderService` interfaces, both can be replaced with mocks:

```csharp
[Fact]
public async Task Initialize_LoadsOrdersIntoView()
{
    var mockView = Substitute.For<IOrderListView>();
    var mockService = Substitute.For<IOrderService>();
    mockService.GetRecentOrdersAsync().Returns(new List<OrderSummary>
    {
        new OrderSummary { Id = 1 }
    });

    var presenter = new OrderListPresenter(mockView, mockService);
    presenter.Initialize();

    mockView.Received().Orders = Arg.Is<IReadOnlyList<OrderSummary>>(
        o => o.Count == 1);
}
```

No UI framework, no browser, no form — pure in-process unit test with full coverage of presentation logic.

## MVP vs. MVC vs. MVVM

| | [MVC](/design-patterns/mvc-pattern/) | MVP | [MVVM](/design-patterns/mvvm-pattern/) |
|---|---|---|---|
| Mediator | Controller | Presenter | ViewModel |
| View updates | Controller pushes to a selected view | Presenter pushes via `IView` interface | Binding pulls automatically |
| View–mediator coupling | Controller does not reference the view | Presenter holds `IView` reference | ViewModel has no view reference |
| Testability of UI logic | Medium | High (mock `IView`) | High (ViewModel has no UI deps) |
| Best suited for | Server-rendered web, REST APIs | WinForms, WebForms, Razor Pages, Android (classic) | WPF, WinUI, MAUI, Blazor, Angular, Vue |

**ASP.NET Core Razor Pages** is structurally close to MVP: the Page Model (code-behind) acts as a Presenter, the `.cshtml` file is the view, and the two are tightly paired — unlike MVC where any controller can render any view.

## Intent

Separate presentation logic from the view by introducing a Presenter that communicates with a passive view through an interface, making all presentation logic independently testable.

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Martin Fowler - [GUI Architectures: Passive View](https://martinfowler.com/eaaDev/PassiveScreen.html)

Martin Fowler - [GUI Architectures: Supervising Controller](https://martinfowler.com/eaaDev/SupervisingPresenter.html)
