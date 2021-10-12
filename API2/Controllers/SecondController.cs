using Microsoft.AspNetCore.Mvc;

namespace API2.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class SecondController : ControllerBase
	{
		[HttpGet]
		public string Get()
		{
			return "Second";
		}
	}
}
