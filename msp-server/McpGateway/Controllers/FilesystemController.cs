using Microsoft.AspNetCore.Mvc;
namespace McpGateway.Controllers
{
	using Microsoft.AspNetCore.Mvc;

	[Route("api/files")]
	public class FilesystemController : ControllerBase
	{
		[HttpGet("list")]
		public IActionResult ListFiles([FromQuery] string path)
		{
			if (!Directory.Exists(path))
				return NotFound("Directory not found");

			var files = Directory.GetFiles(path).Select(Path.GetFileName);
			return Ok(files);
		}
	}

}
