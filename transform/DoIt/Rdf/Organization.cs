using VDS.RDF.Wrapping;

namespace DoIt.Rdf;

public class Organization : GraphWrapperNode
{
    protected Organization(INode node, IGraph graph) : base(node, graph) { }

    internal static Organization Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Organization Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal static Organization Create(string uri, IGraph g) => Wrap(g.CreateUriNode(g.UriFactory.Create(Vocabulary.InstanceBaseUri, uri)), g);

    internal string? Description { set => this.OverwriteNullable(Vocabulary.Description, value); }

    internal string Name { set => this.Overwrite(Vocabulary.Name, value); }

    internal Uri? Website { set => this.Overwrite(Vocabulary.Website, value); }

    internal ISet<Concept> Cause { get => this.Objects(Vocabulary.OrganizationCause, Concept.Wrap, Concept.Wrap); }
}
