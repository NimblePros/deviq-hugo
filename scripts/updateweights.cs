#!/usr/bin/env dotnet-script
// updateweights.cs - Updates Hugo frontmatter weight fields for .md files in a folder
//
// Usage: dotnet run scripts/updateweights.cs <folder-path>
//   or:  dotnet scripts/updateweights.cs <folder-path>
//
// Updates the weight field in each .md file's frontmatter so files are ordered
// alphabetically in the Hugo sidebar (multiples of 10, starting at 10).
// Ignores _index.md and does not recurse into subdirectories.

if (args.Length == 0)
{
  Console.Error.WriteLine("Usage: dotnet run updateweights.cs <folder-path>");
  Console.Error.WriteLine("       dotnet updateweights.cs <folder-path>");
  return 1;
}

var folderPath = args[0];

if (!Directory.Exists(folderPath))
{
  Console.Error.WriteLine($"Error: Folder '{folderPath}' does not exist.");
  return 1;
}

// Collect .md files (no recursion, ignore _index.md), sorted alphabetically
var files = Directory.GetFiles(folderPath, "*.md", SearchOption.TopDirectoryOnly)
  .Where(f => !Path.GetFileName(f).Equals("_index.md", StringComparison.OrdinalIgnoreCase))
  .OrderBy(f => Path.GetFileName(f), StringComparer.OrdinalIgnoreCase)
  .ToList();

if (files.Count == 0)
{
  Console.WriteLine($"No .md files found in '{folderPath}' (excluding _index.md).");
  return 0;
}

int updated = 0;
int weight = 10;

foreach (var file in files)
{
  var fileName = Path.GetFileName(file);
  if (SetWeight(file, weight))
  {
    Console.WriteLine($"  weight: {weight,4} -> {fileName}");
    updated++;
  }
  weight += 10;
}

Console.WriteLine($"\nDone. Updated {updated} of {files.Count} files in '{folderPath}'.");
return 0;

static bool SetWeight(string filePath, int weight)
{
  const string Delimiter = "---";

  var text = File.ReadAllText(filePath);

  if (!text.StartsWith(Delimiter))
  {
    Console.Error.WriteLine($"  Warning: '{Path.GetFileName(filePath)}' has no frontmatter — skipping.");
    return false;
  }

  // Split on newlines, preserving any \r\n line endings
  var nl = text.Contains("\r\n") ? "\r\n" : "\n";
  var lines = text.Split(["\r\n", "\n"], StringSplitOptions.None).ToList();

  // Find the closing --- (must be at least on line 1)
  int endIndex = -1;
  for (int i = 1; i < lines.Count; i++)
  {
    if (lines[i].TrimEnd() == Delimiter)
    {
      endIndex = i;
      break;
    }
  }

  if (endIndex == -1)
  {
    Console.Error.WriteLine($"  Warning: '{Path.GetFileName(filePath)}' has unclosed frontmatter — skipping.");
    return false;
  }

  // Look for an existing weight line inside frontmatter
  int weightLine = -1;
  for (int i = 1; i < endIndex; i++)
  {
    if (lines[i].StartsWith("weight:"))
    {
      weightLine = i;
      break;
    }
  }

  if (weightLine >= 0)
  {
    if (lines[weightLine] == $"weight: {weight}")
    {
      return false; // already correct, no change needed
    }
    lines[weightLine] = $"weight: {weight}";
  }
  else
  {
    // Insert before the closing ---
    lines.Insert(endIndex, $"weight: {weight}");
  }

  File.WriteAllText(filePath, string.Join(nl, lines));
  return true;
}
