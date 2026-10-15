using VDS.RDF.Writing;

namespace VDS.RDF.Wrapping;

// TODO: Read only set and list
public static class GraphWrapperNodeExtensions
{
    public static T? Singular<T>(this GraphWrapperNode subject, string predicate, ValueMapping<T> map, bool throwWhenMissing = false, bool throwWhenMore = false) =>
        subject.Singular(subject.Graph.CreateUriNode(UriFactory.Create(predicate)), map, throwWhenMissing, throwWhenMore);

    public static T? Singular<T>(this GraphWrapperNode subject, INode predicate, ValueMapping<T> map, bool throwWhenMissing = false, bool throwWhenMore = false)
    {
        using var objects = subject.Graph
            .GetTriplesWithSubjectPredicate(subject, predicate)
            .Select(triple => triple.Object)
            .In(subject.Graph)
            .GetEnumerator();

        if (!objects.MoveNext())
        {
            if (throwWhenMissing)
            {
                throw new InvalidOperationException("less than one");
            }

            return map(null);
        }

        var first = objects.Current;

        if (throwWhenMore)
        {
            if (objects.MoveNext())
            {
                throw new InvalidOperationException("more than one");
            }
        }

        return map(first);
    }

    public static void Overwrite<T>(this GraphWrapperNode subject, INode predicate, T value, NodeMapping<T>? map = default)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value));
        }

        map ??= NodeMappings.From;

        subject.Graph.Retract(subject.Graph.GetTriplesWithSubjectPredicate(subject, predicate));
        subject.Graph.Assert(subject, predicate, map(value, subject.Graph));
    }

    public static void OverwriteNullable<T>(this GraphWrapperNode subject, string predicate, T? value, NodeMapping<T>? map = default) =>
        subject.OverwriteNullable(subject.Graph.CreateUriNode(UriFactory.Create(predicate)), value, map);

    public static void OverwriteNullable<T>(this GraphWrapperNode subject, INode predicate, T? value, NodeMapping<T>? map = default)
    {
        subject.Graph.Retract(subject.Graph.GetTriplesWithSubjectPredicate(subject, predicate));

        if (value is null)
        {
            return;
        }

        map ??= NodeMappings.From;

        subject.Graph.Assert(subject, predicate, map(value, subject.Graph));
    }

    public static ISet<T> Objects<T>(this GraphWrapperNode subject, INode predicate, NodeMapping<T> nmap, ValueMapping<T> vmap) =>
        new NodeSet<T>(subject, predicate, TripleSegment.Subject, nmap, vmap);

    public static IDictionary<T, K> Dictionary<T, K>(this GraphWrapperNode subject, INode predicate, NodeMapping<KeyValuePair<T, K>> nmap, ValueMapping<KeyValuePair<T, K>> vmap) =>
        new WrappingDictionary<T, K>(subject, predicate, nmap, vmap);

    public static IList<T> List<T>(this GraphWrapperNode subject, INode predicate, NodeMapping<T> nmap, ValueMapping<T> vmap) =>
        Singular(subject, predicate, ValueMappings.AsList(subject, predicate, nmap, vmap));
}