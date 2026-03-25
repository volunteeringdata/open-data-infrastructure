using Microsoft.AspNetCore.Mvc;
using Query.Services;
using Query.Wrapping;

namespace Query.Controllers;

[Route("/{name}.{format?}")]
[ApiController]
[AllowSynchronousIO]
[FormatFilter]
public class DefaultController(QueryService queryService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(string name, CancellationToken ct)
    {
        var endpoint = EndpointGraph.Instance[name];
        if (endpoint is null)
        {
            return NotFound();
        }

        foreach (var item in endpoint.Parameters.Where(n => n.Required).Select(p => p.Name).Where(n => !Request.Query.ContainsKey(n)))
        {
            ModelState.AddModelError(item, "This query string parameter is required");
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(ProblemDetailsFactory.CreateValidationProblemDetails(HttpContext, ModelState));
        }

        var query = Request.Query.ToDictionary(i => i.Key, i => i.Value.ToString());
        var result = await queryService.ExecuteNamedQueryAsync(endpoint, query, ct);
        return Ok(result);
    }
}
