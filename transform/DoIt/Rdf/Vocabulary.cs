namespace DoIt.Rdf;

internal class Vocabulary
{
    internal const string VocabularyBaseUri = "https://ns.volunteeringdata.io/";
    internal static Uri InstanceBaseUri => new("https://id.volunteeringdata.io/");

    private static readonly NodeFactory Factory = new();

    internal static INode Location { get; } = Node("location");
    internal static INode SessionActivity { get; } = Node("sessionActivity");
    internal static IUriNode Address { get; } = Node("address");
    internal static IUriNode AllowsRemoteParticipation { get; } = Node("allowsRemoteParticipation");
    internal static IUriNode ApplyLink { get; } = Node("applyLink");
    internal static IUriNode Description { get; } = Node("description");
    internal static IUriNode Label { get; } = Node("label");
    internal static IUriNode Latitude { get; } = Node("latitude");
    internal static IUriNode Longitude { get; } = Node("longitude");
    internal static IUriNode Name { get; } = Node("name");
    internal static IUriNode Organisation { get; } = Node("activityOrganisation");
    internal static IUriNode OrganizationCause { get; } = Node("cause");
    internal static IUriNode Requirement { get; } = Node("requirement");
    internal static IUriNode RoleActivity { get; } = Node("roleActivity");
    internal static IUriNode Title { get; } = Node("title");
    internal static IUriNode Website { get; } = Node("website");

    private static IUriNode Node(string name) => AnyNode($"{VocabularyBaseUri}{name}");

    private static IUriNode AnyNode(string uri) => Factory.CreateUriNode(Factory.UriFactory.Create(uri));
}
