namespace McpGateway.Controllers
{
	using Microsoft.AspNetCore.Mvc;
	using System.Diagnostics;

	[Route("api/git")]
	public class GitController : ControllerBase
	{
		[HttpGet("branches")]
		public IActionResult GetBranches([FromQuery] string repoUrl)
		{
			var psi = new ProcessStartInfo("git", $"ls-remote --heads {repoUrl}")
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
