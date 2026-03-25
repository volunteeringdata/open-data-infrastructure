using Microsoft.Extensions.Options;
using VDS.RDF;
using VDS.RDF.Query;

namespace Query.Services;

public class QueryService(HttpClient httpClient, IOptions<QueryServiceOptions> options)
{
    private static readonly NodeFactory factory = new();

    private readonly QueryServiceOptions options = options.Value;

    internal async Task<object?> ExecuteNamedQueryAsync(Wrapping.Endpoint endpoint, Dictionary<string, string> parameters, CancellationToken ct)
    {
        var sparqlText = Parametrize(endpoint, parameters);
        var sparqlClient = new SparqlQueryClient(httpClient, options.SparqlEndpointUri);

        return endpoint.QueryType switch
        {
            SparqlQueryType.Construct or
            SparqlQueryType.Describe or
            SparqlQueryType.DescribeAll => new ResponseContainer
            {
                Graph = await sparqlClient.QueryWithResultGraphAsync(sparqlText, ct),
                Frame = endpoint.Frame,
            },

            _ => await sparqlClient.QueryWithResultSetAsync(sparqlText, ct)
        };
    }

    private static string Parametrize(Wrapping.Endpoint endpoint, Dictionary<string, string> parameters)
    {
        var sparql = new SparqlParameterizedString(endpoint.Sparql);

        foreach (var parameter in endpoint.Parameters)
        {
            if (parameters.TryGetValue(parameter.Name, out var value))
            {
                var valueNode = factory.CreateLiteralNode(value, parameter.Datatype);

                sparql.SetVariable(parameter.Name, valueNode);
            }
        }

        return sparql.ToString();
    }
}
