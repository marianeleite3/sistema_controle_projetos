using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Services;


namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("api/v1/auth")]
    public class AuthController : Controller
    {
        [HttpPost]
        public IActionResult Auth(string username, string password)
        {

            if (username == "admin" && password == "123456")
            {
                var token = TokenService.GenerateToken(new Model.Employee());
                return Ok(token);
            }

            return BadRequest("username or password invalid");
        }
    }
}
