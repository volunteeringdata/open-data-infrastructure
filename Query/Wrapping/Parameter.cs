using Microsoft.OpenApi;
using VDS.RDF;
using VDS.RDF.Parsing;
using VDS.RDF.Wrapping;

namespace Query.Wrapping;

internal class Parameter : GraphWrapperNode
{
    protected Parameter(INode node, IGraph graph) : base(node, graph) { }

    internal static Parameter Wrap(INode node, IGraph graph) => new(node, graph);

    internal static Parameter Wrap(GraphWrapperNode node) => Wrap(node, node.Graph);

    internal string Name { get => this.Singular(Vocabulary.ParameterName, ValueMappings.As<string>); }
 
    internal string Description { get => this.Singular(Vocabulary.ParameterDescription, ValueMappings.As<string>); }

    private Uri? DatatypeInternal { get => this.Singular(Vocabulary.Datatype, ValueMappings.As<Uri>); }

    internal Uri Datatype => DatatypeInternal ?? new Uri(XmlSpecsHelper.XmlSchemaDataTypeString);

    internal string? Example { get => this.Singular(Vocabulary.Example, ValueMappings.As<string>); }

    internal bool Required { get => this.Singular(Vocabulary.Required, ValueMappings.As<bool>, throwWhenMissing: true); }

    internal JsonSchemaType JsonSchemaType => DatatypeInternal?.ToString() switch
    {
        null or
        XmlSpecsHelper.XmlSchemaDataTypeString => JsonSchemaType.String,

        XmlSpecsHelper.XmlSchemaDataTypeInteger or
        XmlSpecsHelper.XmlSchemaDataTypeDouble => JsonSchemaType.Number,

        _ => throw new Exception($"unknown literal parameter datatype {DatatypeInternal}")
    };

    internal string JsonSchemaTypeNodeString => JsonSchemaType switch
    {
        JsonSchemaType.String => "string",
        JsonSchemaType.Number => "number",
        _ => throw new Exception($"unknown literal parameter datatype {JsonSchemaType}")
    };
}
