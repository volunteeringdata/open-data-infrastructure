using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using Query.Wrapping;
using System.Text.Json.Nodes;
using VDS.RDF;
using VDS.RDF.Parsing;
using VDS.RDF.Query;

namespace Query.Controllers;

[Route("/openapi.json")]
[ApiController]
[AllowSynchronousIO]
public partial class OpenApiController() : ControllerBase
{
    private const string graphResponse = "graphResponse";
    private const string nonGraphResponse = "nonGraphResponse";

    [HttpGet]
    public async Task<OpenApiDocument> Get(CancellationToken ct) => new()
    {
        Info = new()
        {
            Title = "OpenVolunteering Hackathon API", // TODO: Don't hardcode
            Version = "1" // TODO: Don't hardcode
        },
        Paths = await GetPaths(ct),
        Components = new OpenApiComponents
        {
            Responses = new Dictionary<string, IOpenApiResponse>
            {
                [graphResponse] = new OpenApiResponse
                {
                    Description = "OK",
                    Content = MimeTypesHelper.Definitions
                        .Where(d => d.CanWriteRdfDatasets || d.CanWriteRdf)
                        .Select(d => d.CanonicalMimeType)
                        .Distinct()
                        .ToDictionary(d => d, d => new OpenApiMediaType()),
                },
                [nonGraphResponse] = new OpenApiResponse
                {
                    Description = "OK",
                    Content = MimeTypesHelper.Definitions
                        .Where(d => d.CanWriteSparqlResults)
                        .Select(d => d.CanonicalMimeType)
                        .Distinct()
                        .ToDictionary(d => d, d => new OpenApiMediaType { }),
                },
            },
        },
    };


    private static async Task<OpenApiPaths> GetPaths(CancellationToken ct)
    {
        var paths = new OpenApiPaths();

        foreach (var endpoint in EndpointGraph.Instance.Endpoints)
        {
            var sparqlQuery = new SparqlQueryParser().ParseFromString(endpoint.Sparql);
            var responses = new OpenApiResponses
            {
                ["200"] = sparqlQuery.QueryType switch
                {
                    SparqlQueryType.Construct or
                    SparqlQueryType.Describe or
                    SparqlQueryType.DescribeAll => new OpenApiResponseReference(graphResponse),

                    _ => new OpenApiResponseReference(nonGraphResponse),
                },
            };

            var pathItem = new OpenApiPathItem
            {
                Operations = new()
                {
                    [HttpMethod.Get] = new OpenApiOperation
                    {
                        Summary = endpoint.Name,
                        Description = $"""
                            {endpoint.Description}

                            Underlying SPARQL query:
                            ```sparql
                            {endpoint.Sparql}
                            ```
                            """,
                        Parameters = endpoint is null ? [] : [.. endpoint.Parameters.Select(p => new OpenApiParameter {
                                Name = p.Name,
                                Description = p.Description,
                                In = ParameterLocation.Query,
                                Schema = new OpenApiSchema {
                                    Type = p.JsonSchemaType,
                                },
                                Required = p.Required,
                                Example = JsonValue.Create(p.Example),
                            })],
                        Responses = responses
                    }
                }
            };

            paths.Add($"/{endpoint.Path}", pathItem);
        }

        return paths;
    }
}
