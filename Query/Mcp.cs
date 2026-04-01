using ModelContextProtocol.Protocol;
using ModelContextProtocol.Server;
using Query.Services;
using Query.Wrapping;
using System.Text.Json;
using System.Text.Json.Nodes;
using VDS.RDF;
using VDS.RDF.Query;
using VDS.RDF.Writing;
using StringWriter = VDS.RDF.Writing.StringWriter;

namespace Query;

public static class Mcp
{
    private static readonly IRdfWriter graphWriter = new CompressingTurtleWriter();
    private static readonly ISparqlResultsWriter sparqlWriter = new SparqlHtmlWriter();

    internal static async ValueTask<ListToolsResult> ListTools(RequestContext<ListToolsRequestParams> _, CancellationToken ct) =>
        new()
        {
            Tools = EndpointGraph.Instance.Endpoints
                .Select(static endpoint =>
                    new Tool
                    {
                        Name = endpoint.Path,
                        Title = endpoint.Name,
                        Description = $"""
                            {endpoint.Description}

                            Underlying SPARQL query:
                            ```sparql
                            {endpoint.Sparql}
                            ```
                            """,
                        InputSchema = JsonSerializer.SerializeToElement(new
                        {
                            type = "object",
                            properties = new JsonObject(endpoint.Parameters.ToDictionary(
                                p => p.Name,
                                p => new JsonObject
                                {
                                    ["title"] = p.Name,
                                    ["type"] = p.JsonSchemaTypeNodeString,
                                    ["description"] = $"""
                                    {p.Description}
                                    
                                    Example value: {p.Example}
                                    """,
                                    
                                } as JsonNode)!),
                            required = endpoint.Parameters.Where(p => p.Required).Select(p => p.Name).ToArray()
                        })
                    }
                )
            .ToList()
        };

    internal static async ValueTask<CallToolResult> CallTool(RequestContext<CallToolRequestParams> context, CancellationToken ct) =>
        new()
        {
            Content = [
                new TextContentBlock {
                    Text = Serialize(
                        await context.Services!.GetRequiredService<QueryService>().ExecuteNamedQueryAsync(
                            EndpointGraph.Instance[context.Params.Name],
                            context.Params.Arguments!.ToDictionary(
                                x => x.Key,
                                x => x.Value.GetString()!
                            ),
                            ct
                        )
                    )
                }
            ]
        };

    private static string Serialize(object? result)
    {
        return result switch
        {
            null => throw new Exception("Result was nothing"),
            ResponseContainer container => StringWriter.Write(container.Graph, graphWriter),
            SparqlResultSet sparql => StringWriter.Write(sparql, sparqlWriter),
            _ => throw new Exception($"Unknown result type {result.GetType()}")
        };
    }
}
