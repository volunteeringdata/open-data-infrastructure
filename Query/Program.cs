using Query;
using Query.Formatters;
using Query.Services;
using static VDS.RDF.MimeTypesHelper;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options =>
{
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultCsvExtension, Csv[0]);
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultJsonLdExtension, JsonLd[0]);
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultTurtleExtension, Turtle[0]);
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultRdfXmlExtension, RdfXml[0]);
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultNTriplesExtension, NTriples[0]);
    options.FormatterMappings.SetMediaTypeMappingForFormat(DefaultHtmlExtension, Html[0]);

    options.ReturnHttpNotAcceptable = true;

    // So we don't get default JSON serializations of things
    //options.OutputFormatters.Clear();

    options.OutputFormatters.Insert(0, new OpenApiFormatter());

    options.OutputFormatters.Insert(0, new SparqlFormatter());
    options.OutputFormatters.Insert(0, new GraphFormatter());

    // Added last so ends up in position 0 for highest priority
    options.OutputFormatters.Insert(0, new JsonLdFormatter());
});

builder.Services.AddHttpClient();

builder.Services.AddSingleton<QueryService>();

builder.Services.AddMcpServer()
    .WithHttpTransport()
    .WithListToolsHandler(Mcp.ListTools)
    .WithCallToolHandler(Mcp.CallTool);

builder.Services.AddCors();

builder.Services.AddOptions<QueryServiceOptions>().BindConfiguration("QueryService");

builder.Services.AddRazorPages();

builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("Proxy"));

var app = builder.Build();

app.MapControllers();
app.UseSwaggerUI(static options => options.SwaggerEndpoint("/openapi.json", "live"));
app.MapMcp("mcp");
app.UseCors(builder => builder
     .AllowAnyOrigin()
     .AllowAnyMethod()
     .AllowAnyHeader());
app.MapRazorPages();
app.MapReverseProxy();

app.Run();
