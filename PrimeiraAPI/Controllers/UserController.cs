using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Infra;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/user")]
    public class UserController : Controller
    {

        private readonly IUserRepository _userRepository;

        public UserController(IUserRepository userRepository)
        {
            _userRepository = userRepository ?? throw new ArgumentException(nameof(userRepository));

        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(UserViewModel userView)
        {

            var user = new User(userView.UserCode, userView.FullName, userView.NickName, userView.Origem, userView.Status, userView.HourlyCost, userView.Responsibility, userView.SecurityKey);

            _userRepository.Add(user);
            return Ok();
        }

        [HttpGet]
        public IActionResult Get()
        {

            var user = _userRepository.Get();
            return Ok();
        }

    }
}
