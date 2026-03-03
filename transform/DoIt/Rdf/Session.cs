using VDS.RDF.Wrapping;

namespace DoIt.Rdf;

public class Session : GraphWrapperNode
{
    protected Session(INode node, IGraph graph) : base(node, graph) { }

    internal static Session Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Session Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal static Session Create(string uri, IGraph g) => Wrap(g.CreateUriNode(g.UriFactory.Create(Vocabulary.InstanceBaseUri, uri)), g);

    internal Activity Activity { set => this.Overwrite(Vocabulary.SessionActivity, value, Activity.Wrap); }

    internal ISet<Location> Locations { get => this.Objects(Vocabulary.Location, Location.Wrap, Location.Wrap); }
}
