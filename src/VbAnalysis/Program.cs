using System.Text;
using System.Text.Json;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.Text;
using Microsoft.CodeAnalysis.VisualBasic;
using Microsoft.CodeAnalysis.VisualBasic.Syntax;

static string Clip(string value, int max) => value.Length > max ? value[..max] : value;
static object Range(SyntaxNode node) {
    var span = node.GetLocation().GetLineSpan();
    return new { startLine = span.StartLinePosition.Line + 1, startColumn = span.StartLinePosition.Character + 1,
        endLine = span.EndLinePosition.Line + 1, endColumn = span.EndLinePosition.Character + 1 };
}
static string? Name(SyntaxNode node) => node switch {
    NamespaceStatementSyntax n => n.Name.ToString(),
    TypeStatementSyntax n => n.Identifier.ValueText,
    EnumStatementSyntax n => n.Identifier.ValueText,
    MethodStatementSyntax n => n.Identifier.ValueText,
    SubNewStatementSyntax => "New",
    PropertyStatementSyntax n => n.Identifier.ValueText,
    EventStatementSyntax n => n.Identifier.ValueText,
    DelegateStatementSyntax n => n.Identifier.ValueText,
    _ => null
};
static SyntaxNode Declaration(SyntaxNode node) {
    var parent = node.Parent;
    return parent != null && parent.GetType().Name.EndsWith("BlockSyntax") && parent.ChildNodes().FirstOrDefault() == node
        ? parent : node;
}
try {
    if (args.Length < 2 || !new[] { "outline", "inspect", "calls" }.Contains(args[0]))
        throw new ArgumentException("Usage: VbAnalysis <outline|inspect|calls> FILE [--line N] [--limit N] [--max-chars N]");
    string command = args[0], file = Path.GetFullPath(args[1]);
    int? line = null; int limit = 50, maxChars = 4000;
    for (int i = 2; i < args.Length; i += 2) {
        if (i + 1 >= args.Length || !int.TryParse(args[i + 1], out int n) || n < 1)
            throw new ArgumentException("Options require positive integer values.");
        switch (args[i]) {
            case "--line": line = n; break;
            case "--limit": limit = Math.Min(n, 100); break;
            case "--max-chars": maxChars = Math.Min(n, 12000); break;
            default: throw new ArgumentException("Unknown option: " + args[i]);
        }
    }
    if (command != "outline" && line == null) throw new ArgumentException("inspect and calls require --line (the declaration start line from outline).");
    if (!File.Exists(file)) throw new FileNotFoundException("Input file does not exist.", file);
    if (!string.Equals(Path.GetExtension(file), ".vb", StringComparison.OrdinalIgnoreCase)) throw new ArgumentException("Expected a .vb source file.");
    if (new FileInfo(file).Length > 5 * 1024 * 1024) throw new ArgumentException("Input exceeds the 5 MiB file limit.");
    // UTF-8 without BOM is strict; StreamReader recognizes UTF-8/UTF-16/UTF-32 BOMs.
    using var reader = new StreamReader(file, new UTF8Encoding(false, true), true);
    var text = SourceText.From(reader.ReadToEnd());
    var tree = VisualBasicSyntaxTree.ParseText(text, path: file);
    var root = tree.GetRoot();
    var declarations = root.DescendantNodes().Where(n => Name(n) != null).Select(n => new { header = n, node = Declaration(n) }).ToArray();
    var issues = tree.GetDiagnostics().Where(d => d.Severity == DiagnosticSeverity.Error).ToArray();
    var results = new List<object>();
    int total;
    if (command == "outline") {
        total = declarations.Length;
        foreach (var d in declarations.Take(limit)) results.Add(new { name = Clip(Name(d.header)!, 200), kind = d.node.GetType().Name, range = Range(d.node) });
    } else {
        var matches = declarations.Where(d => d.node.GetLocation().GetLineSpan().StartLinePosition.Line + 1 == line).ToArray();
        if (matches.Length != 1) throw new ArgumentException("--line must identify exactly one declaration start from outline.");
        var selected = matches[0];
        if (command == "inspect") {
            var source = selected.node.ToString();
            total = 1;
            results.Add(new { name = Name(selected.header), range = Range(selected.node), text = Clip(source, maxChars), textTruncated = source.Length > maxChars });
        } else {
            if (selected.node is not MethodBlockSyntax && selected.node is not ConstructorBlockSyntax)
                throw new ArgumentException("calls requires a Sub, Function, or constructor block.");
            var calls = selected.node.DescendantNodes().OfType<InvocationExpressionSyntax>().ToArray();
            total = calls.Length;
            foreach (var call in calls.Take(limit)) {
                string expression = call.Expression.ToString();
                results.Add(new { expression = Clip(expression, 200), expressionTruncated = expression.Length > 200,
                    range = Range(call), classification = "invocation-syntax", resolvedSymbol = (string?)null });
            }
        }
    }
    Console.WriteLine(JsonSerializer.Serialize(new {
        schemaVersion = 1, toolVersion = "0.1.0", command, file = file.Replace('\\', '/'), analysis = "syntax-only",
        total, returned = results.Count, truncated = results.Count < total,
        parseErrorCount = issues.Length,
        diagnostics = issues.Take(10).Select(d => new { id = d.Id, message = Clip(d.GetMessage(), 300), line = d.Location.GetLineSpan().StartLinePosition.Line + 1 }),
        limitations = new[] { "No project references or semantic resolution.", "Default preprocessor symbols only; inactive conditional branches are excluded.", "Invocation syntax may represent array/default-property access; includes nested lambda invocations and excludes bare member access and object creation." },
        results
    }));
    return issues.Length == 0 ? 0 : 2;
} catch (Exception ex) {
    Console.Error.WriteLine(JsonSerializer.Serialize(new { error = Clip(ex.Message, 1000) }));
    return 1;
}
