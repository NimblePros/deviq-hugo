#!/usr/bin/env dotnet
// Update frontmatter `weight` values for .md files in a folder,
// sorted alphabetically, as multiples of 10. Ignores _index.md.
// Usage: dotnet updateweights.cs [folder]
//   If folder is omitted, uses the current directory.

using System.Text.RegularExpressions;

var folder = args.Length > 0 ? args[0] : Directory.GetCurrentDirectory();

if (!Directory.Exists(folder))
{
    Console.Error.WriteLine($"Folder not found: {folder}");
    return 1;
}

var files = Directory.GetFiles(folder, "*.md", SearchOption.TopDirectoryOnly)
    .Where(f => !Path.GetFileName(f).Equals("_index.md", StringComparison.OrdinalIgnoreCase))
    .OrderBy(f => Path.GetFileName(f), StringComparer.OrdinalIgnoreCase)
    .ToList();

if (files.Count == 0)
{
    Console.WriteLine("No .md files found (excluding _index.md).");
    return 0;
}

var weightPattern = new Regex(@"^weight\s*:\s*\d+\s*$", RegexOptions.Multiline);
var frontmatterPattern = new Regex(@"^---\s*\n(.*?)\n---", RegexOptions.Singleline);

int updated = 0, weight = 10;

foreach (var file in files)
{
    var content = File.ReadAllText(file);
    var newWeight = weight;
    weight += 10;

    var fm = frontmatterPattern.Match(content);
    string newContent;

    if (fm.Success)
    {
        var fmBody = fm.Groups[1].Value;

        if (weightPattern.IsMatch(fmBody))
        {
            // Replace existing weight
            var updatedFm = weightPattern.Replace(fmBody, $"weight: {newWeight}");
            newContent = content.Replace(fm.Groups[1].Value, updatedFm);
        }
        else
        {
            // Append weight to existing frontmatter
            var updatedFm = fmBody + $"\nweight: {newWeight}";
            newContent = content.Replace(fm.Groups[1].Value, updatedFm);
        }
    }
    else
    {
        // No frontmatter — prepend it
        newContent = $"---\nweight: {newWeight}\n---\n" + content;
    }

    if (newContent != content)
    {
        File.WriteAllText(file, newContent);
        Console.WriteLine($"  {Path.GetFileName(file)}: weight = {newWeight}");
        updated++;
    }
    else
    {
        Console.WriteLine($"  {Path.GetFileName(file)}: weight = {newWeight} (unchanged)");
    }
}

Console.WriteLine($"\nDone. {updated} file(s) updated in: {folder}");
return 0;
