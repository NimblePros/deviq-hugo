---
title: Model-View-ViewModel (MVVM) Design Pattern

date: 2026-03-09

description: The Model-View-ViewModel (MVVM) pattern separates UI state and behavior into a ViewModel that the View data-binds to automatically, removing the need for imperative UI update code. Learn how MVVM works in C# with WPF/MAUI examples, and how it compares to MVC and MVP.
---

## What is the MVVM Pattern?

Model-View-ViewModel (MVVM) is an architectural pattern that separates an application into three components:

- **Model** — the application's data, business logic, and rules. The model is entirely independent of the UI.
- **View** — the UI layer. In MVVM the view declares *data bindings* to the ViewModel rather than containing imperative update code. The view reacts automatically when the ViewModel's state changes.
- **ViewModel** — adapts the model for presentation and exposes it as observable properties and commands. The ViewModel has **no reference to the View** — it knows nothing about how it is rendered.

The crucial difference from [MVC](/design-patterns/mvc-pattern/) and [MVP](/design-patterns/mvp-pattern/) is the **data-binding contract**: the platform's binding engine keeps the view in sync with the ViewModel automatically, so the ViewModel never needs to push updates to the view imperatively.

```
Model ◀──▶ ViewModel ◀══(binding)══▶ View
                                      User Input
                                          │
                                          ▼
                                      Command on VM
```

MVVM was introduced by John Gossman at Microsoft in 2005 for WPF and has since become the dominant pattern for data-binding-rich platforms: WPF, WinUI 3, .NET MAUI, Xamarin, Blazor, Angular, Vue, and Knockout.

## MVVM Participants

### Model

Domain entities, services, and repositories. The model owns business logic; it has no knowledge of the ViewModel or View.

### ViewModel

The ViewModel is the heart of MVVM. It:

1. **Exposes observable properties** — implements `INotifyPropertyChanged` (or uses a source generator / toolkit) so the binding engine can react when values change.
2. **Exposes commands** — wraps actions the user can invoke (button clicks, menu selections) as `ICommand` implementations so the View can bind to them without code-behind.
3. **Is fully unit-testable** — because the ViewModel has no dependency on any view type, its entire logic can be exercised in plain unit tests.

### View

The view (a XAML file, Razor component, or HTML template) declares bindings to the ViewModel's properties and commands. Ideally the view's code-behind contains nothing but the constructor and the line that sets the `DataContext`.

## C# Example (WPF / .NET MAUI style)

### Model

```csharp
public class Product
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public decimal Price { get; init; }
}
```

### ViewModel using CommunityToolkit.Mvvm

The [CommunityToolkit.Mvvm](https://learn.microsoft.com/en-us/dotnet/communitytoolkit/mvvm/) NuGet package provides source generators that eliminate most MVVM boilerplate:

```csharp
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

public partial class ProductListViewModel : ObservableObject
{
    private readonly IProductService _productService;

    // Source generator produces a public ObservableCollection<Product> Products property
    // and raises PropertyChanged automatically.
    [ObservableProperty]
    private ObservableCollection<Product> _products = new();

    [ObservableProperty]
    private Product? _selectedProduct;

    [ObservableProperty]
    private bool _isLoading;

    public ProductListViewModel(IProductService productService)
    {
        _productService = productService;
    }

    [RelayCommand]
    private async Task LoadProductsAsync()
    {
        IsLoading = true;
        var items = await _productService.GetAllAsync();
        Products = new ObservableCollection<Product>(items);
        IsLoading = false;
    }
}
```

### View (XAML)

```xml
<Window x:Class="MyApp.ProductListView"
        xmlns:vm="clr-namespace:MyApp.ViewModels">
    <Window.DataContext>
        <vm:ProductListViewModel />
    </Window.DataContext>

    <StackPanel>
        <Button Content="Load Products"
                Command="{Binding LoadProductsCommand}" />
        <ProgressBar IsIndeterminate="True"
                     Visibility="{Binding IsLoading, Converter={...}}" />
        <ListBox ItemsSource="{Binding Products}"
                 SelectedItem="{Binding SelectedProduct}"
                 DisplayMemberPath="Name" />
    </StackPanel>
</Window>
```

The view code-behind is minimal:

```csharp
public partial class ProductListView : Window
{
    public ProductListView()
    {
        InitializeComponent();
    }
}
```

## INotifyPropertyChanged Without a Toolkit

Without a toolkit, the pattern requires implementing `INotifyPropertyChanged` manually:

```csharp
public class ProductListViewModel : INotifyPropertyChanged
{
    private ObservableCollection<Product> _products = new();

    public ObservableCollection<Product> Products
    {
        get => _products;
        set
        {
            if (_products == value) return;
            _products = value;
            OnPropertyChanged();
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
```

On modern projects the toolkit approach is strongly preferred.

## Commands

Commands let the view bind user gestures directly to ViewModel logic without code-behind. The classic implementation is `RelayCommand`:

```csharp
public class RelayCommand : ICommand
{
    private readonly Action _execute;
    private readonly Func<bool>? _canExecute;

    public RelayCommand(Action execute, Func<bool>? canExecute = null)
    {
        _execute = execute;
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;
    public void Execute(object? parameter) => _execute();
    public event EventHandler? CanExecuteChanged;
    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}
```

`CommunityToolkit.Mvvm`'s `[RelayCommand]` source generator produces this automatically.

## Testing the ViewModel

Because the ViewModel has no reference to any view type, it is straightforward to test:

```csharp
[Fact]
public async Task LoadProductsCommand_PopulatesProducts()
{
    var mockService = Substitute.For<IProductService>();
    mockService.GetAllAsync().Returns(new List<Product>
    {
        new Product { Id = 1, Name = "Widget", Price = 9.99m }
    });

    var vm = new ProductListViewModel(mockService);
    await vm.LoadProductsCommand.ExecuteAsync(null);

    Assert.Single(vm.Products);
    Assert.Equal("Widget", vm.Products[0].Name);
}
```

No UI framework required — pure in-process test.

## MVVM in Web Frameworks

MVVM is not limited to XAML platforms:

- **Blazor** — a `@code` block in a `.razor` component acts as the ViewModel; properties trigger re-renders automatically.
- **Angular** — the component class is the ViewModel; templates bind with `{{ }}` and `[(ngModel)]`.
- **Vue** — the Options API object or Composition API `reactive`/`ref` values are the ViewModel; the template binds declaratively.

## MVVM vs. MVC vs. MVP

| | [MVC](/design-patterns/mvc-pattern/) | [MVP](/design-patterns/mvp-pattern/) | MVVM |
|---|---|---|---|
| Mediator | Controller | Presenter | ViewModel |
| View update mechanism | Controller pushes imperatively | Presenter pushes via `IView` interface | Binding pulls automatically |
| Mediator–View coupling | None (controller renders any view) | Strong (holds `IView` reference) | None (ViewModel unaware of View) |
| Testability of UI logic | Medium | High (mock `IView`) | High (no UI deps on ViewModel) |
| Best suited for | Server-rendered web, REST APIs | WinForms, WebForms, Razor Pages | WPF, WinUI, MAUI, Blazor, Angular, Vue |

## Intent

Separate presentation state and behavior into a ViewModel that the View data-binds to automatically, so that all UI logic is independently testable and the View contains no logic of its own.

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

John Gossman - [Introduction to Model/View/ViewModel pattern](https://docs.microsoft.com/archive/blogs/johngossman/introduction-to-modelviewviewmodel-pattern-for-building-wpf-apps)

Microsoft - [CommunityToolkit.Mvvm documentation](https://learn.microsoft.com/en-us/dotnet/communitytoolkit/mvvm/)

Microsoft - [Data binding overview (WPF)](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/data/)
