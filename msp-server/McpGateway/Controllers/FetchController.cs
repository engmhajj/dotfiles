using Microsoft.AspNetCore.Mvc;

namespace McpGateway.Controllers
{

	[Route("api/fetch")]
	public class FetchController : ControllerBase
	{
		private readonly IHttpClientFactory _clientFactory;

		public FetchController(IHttpClientFactory factory)
		{
			_clientFactory = factory;
		}

		[HttpGet("url")]
		public async Task<IActionResult> FetchUrl([FromQuery] string url)
		{
			var client = _clientFactory.CreateClient();
			var response = await client.GetAsync(url);
			var content = await response.Content.ReadAsStringAsync();
			return Content(content, "text/html");
		}
	}

}
