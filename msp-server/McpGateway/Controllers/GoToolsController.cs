namespace McpGateway.Controllers
{
	using Microsoft.AspNetCore.Mvc;
	using System.Diagnostics;

	[Route("api/tools")]
	public class GoToolsController : ControllerBase
	{
		[HttpGet("run")]
		public IActionResult RunGoTool()
		{
			var psi = new ProcessStartInfo("go", "-C /path/to/mcp-tools run ./cmd/mcp-tools/main.go")
			{
				RedirectStandardOutput = true
			};
			var proc = Process.Start(psi);
			var output = proc!.StandardOutput.ReadToEnd();
			proc.WaitForExit();

			return Content(output, "text/plain");
		}
	}

}
