using VDS.RDF.Wrapping;

namespace DoIt.Rdf;

public class Role : GraphWrapperNode
{
    protected Role(INode node, IGraph graph) : base(node, graph) { }

    internal static Role Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Role Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal static Role Create(string uri, IGraph g) => Wrap(g.CreateUriNode(g.UriFactory.Create(Vocabulary.InstanceBaseUri, uri)), g);

    internal Activity Activity { set => this.Overwrite(Vocabulary.RoleActivity, value, Activity.Wrap); }
  
    internal Uri? ApplyLink { set => this.OverwriteNullable(Vocabulary.ApplyLink, value); }

    internal ISet<Concept> Requirement { get => this.Objects(Vocabulary.Requirement, Concept.Wrap, Concept.Wrap); }
}
