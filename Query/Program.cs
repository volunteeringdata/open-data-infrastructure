using Microsoft.Extensions.FileProviders;
using Web;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddNamedQuery(options => options.Definitions = new ManifestEmbeddedFileProvider(typeof(Program).Assembly, "Endpoints"));

builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("Proxy"));

var app = builder.Build();

app.UseNamedQuery();
app.MapReverseProxy();

app.Run();
