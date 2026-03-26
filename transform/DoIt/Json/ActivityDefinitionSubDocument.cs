namespace DoIt.Json;

public class ActivityDefinitionSubDocument : Identified
{
    // activitiesSummary (all empty arrays)

    // app (redundant with appSummary)

    [JsonPropertyName("appSummary")] public required App App { get; set; }

    [JsonPropertyName("measurementUnitSummary")] public required MeasurementUnit MeasurementUnit { get; set; }

    [JsonPropertyName("title")] public required string Title { get; set; }

    [JsonPropertyName("description")] public string? Description { get; set; }

    [JsonPropertyName("type")] public required string Type { get; set; }

    [JsonPropertyName("coverImage")] public Uri? CoverImage { get; set; }

    [JsonPropertyName("eventType")] public string? EventType { get; set; }

    [JsonPropertyName("causeOptions")] public required IEnumerable<OptionItem> Causes { get; set; }

    [JsonPropertyName("requirementOptions")] public required IEnumerable<OptionItem> Requirements { get; set; }

    [JsonPropertyName("locationOption")] public required string LocationOption { get; set; }

    [JsonPropertyName("organizationSubDocument")] public required OrganizationSubDocument Organization { get; set; }

    [JsonPropertyName("volunteerRequirements")] public required IEnumerable<string> VolunteerRequirements { get; set; }

    [JsonPropertyName("volunteerRewards")] public required IEnumerable<string> VolunteerRewards { get; set; }
}
