using VDS.RDF.Wrapping;

namespace DoIt.Rdf;

public class Location : GraphWrapperNode
{
    protected Location(INode node, IGraph graph) : base(node, graph) { }

    internal static Location Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Location Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal static Location Create(string uri, IGraph g) => Wrap(g.CreateUriNode(g.UriFactory.Create(Vocabulary.InstanceBaseUri, uri)), g);

    internal string? Name { set => this.Overwrite(Vocabulary.Name, value); }

    internal string? Address { set => this.Overwrite(Vocabulary.Address, value); }

    internal double? Latitude { set => this.OverwriteNullable(Vocabulary.Latitude, value); }

    internal double? Longitude { set => this.OverwriteNullable(Vocabulary.Longitude, value); }
}
