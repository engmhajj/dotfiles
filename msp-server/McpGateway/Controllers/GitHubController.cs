using Microsoft.AspNetCore.Mvc;
namespace McpGateway.Controllers
{
	[Route("api/github")]
	public class GitHubController : ControllerBase
	{
		private readonly IHttpClientFactory _clientFactory;

		public GitHubController(IHttpClientFactory factory)
		{
			_clientFactory = factory;
		}

		[HttpGet("repo/{owner}/{repo}")]
		public async Task<IActionResult> GetRepo(string owner, string repo)
		{
			var token = Environment.GetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN");
			if (string.IsNullOrEmpty(token))
				return Unauthorized("GitHub token missing");

			var client = _clientFactory.CreateClient();
			client.DefaultRequestHeaders.Add("User-Agent", "MCP-Gateway");
			client.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");

			var url = $"https://api.github.com/repos/{owner}/{repo}";
			var response = await client.GetAsync(url);
			var body = await response.Content.ReadAsStringAsync();

			return Content(body, "application/json");
		}
	}
}
