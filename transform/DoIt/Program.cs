using DoIt.Rdf;
using System.Text.Json;
using VDS.RDF.Writing;
using Json = DoIt.Json;

var inputJsonFile = Path.Combine(Environment.CurrentDirectory, args[0]);
var outputRdfFile = Path.Combine(Environment.CurrentDirectory, args[1]);

var activities = await JsonSerializer.DeserializeAsync<IEnumerable<Json.Activity>>(File.OpenRead(inputJsonFile));

var targetGraph = new Graph();

foreach (var source in activities!)
{
    var activity = Activity.Create(source.Id.Value, targetGraph);
    activity.Title = source.Details.Title;
    activity.Description = source.Details.Description;
    activity.AllowsRemoteParticipation = source.IsOnline;

    activity.Organization = Organization.Create(source.Details.Organization.Id.Value, targetGraph);
    activity.Organization.Name = source.Details.Organization.Name;
    activity.Organization.Description = source.Details.Organization.Description;
    if (source.Details.Organization.WebsiteLink is Uri websiteLink)
    {
        activity.Organization.Website = websiteLink;
    }
    activity.Organization.Cause.UnionWith(source.Details.Organization.Causes.Select(c =>
    {
        var option = Concept.Create(c.Id.Value, targetGraph);
        option.Title = c.DisplayName;
        return option;
    }));

    var role = Role.Create($"r{source.Id.Value}", targetGraph);
    role.Activity = activity;
    role.ApplyLink = source.ExternalApplyLink;
    role.Requirement.UnionWith(source.Details.Requirements.Select(c =>
    {
        var option = Concept.Create(c.Id.Value, targetGraph);
        option.Title = c.DisplayName;
        return option;
    }));

    var session = Session.Create($"s{source.Id.Value}", targetGraph);
    session.Activity = activity;
    session.Locations.UnionWith(source.Regions.Select(r =>
    {
        var location = Location.Create(r.Id.Value, targetGraph);
        location.Name = r.DisplayName;
        location.Longitude = r.GeocenterLocation?.Lon;
        location.Latitude = r.GeocenterLocation?.Lat;
        return location;
    }));
    if (source.Address is Json.Address address)
    {
        var location = Location.Create(address.Id.Value, targetGraph);
        location.Address = address.Street;
        location.Longitude = address.Location.Coordinates[0];
        location.Latitude = address.Location.Coordinates[1];
        session.Locations.Add(location);
    }
}

var turtleWriter = new CompressingTurtleWriter();
turtleWriter.DefaultNamespaces.AddNamespace("id", Vocabulary.InstanceBaseUri);
turtleWriter.DefaultNamespaces.AddNamespace("", new Uri(Vocabulary.VocabularyBaseUri));
turtleWriter.Save(targetGraph, outputRdfFile);
