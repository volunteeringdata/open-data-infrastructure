using VDS.RDF.Wrapping;

namespace DoIt.Rdf;

public class Concept : GraphWrapperNode
{
    protected Concept(INode node, IGraph graph) : base(node, graph) { }

    internal static Concept Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Concept Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal static Concept Create(string uri, IGraph g) => Wrap(g.CreateUriNode(g.UriFactory.Create(Vocabulary.InstanceBaseUri, uri)), g);

    internal string Title { set => this.Overwrite(Vocabulary.Label, value); }
    internal string Description { set => this.Overwrite(Vocabulary.Description, value); }
}
