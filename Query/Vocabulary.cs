using VDS.RDF;

namespace Query;

internal class Vocabulary
{
    internal const string VocabularyBaseUri = "urn:named-query:";

    private static readonly NodeFactory Factory = new();

    internal static IUriNode Path { get; } = Node("path");
    internal static IUriNode EndpointName { get; } = Node("endpointName");
    internal static IUriNode EndpointDescription { get; } = Node("endpointDescription");
    internal static IUriNode Parameter { get; } = Node("parameter");
    internal static IUriNode ParameterName { get; } = Node("parameterName");
    internal static IUriNode ParameterDescription { get; } = Node("parameterDescription");
    internal static IUriNode Example { get; } = Node("example");
    internal static IUriNode Datatype { get; } = Node("datatype");
    internal static IUriNode Required { get; } = Node("required");

    private static IUriNode Node(string name) => AnyNode($"{VocabularyBaseUri}{name}");

    private static IUriNode AnyNode(string uri) => Factory.CreateUriNode(Factory.UriFactory.Create(uri));
}
