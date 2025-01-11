using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Infra;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;
namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/financiallaunch")]
    public class FinancialLaunchController : Controller
    {
        private readonly IFinancialLaunchRepository _financialLaunchRepository;

        public FinancialLaunchController(IFinancialLaunchRepository _financialLaunchRepository)
        {
            _financialLaunchRepository = _financialLaunchRepository ?? throw new ArgumentException(nameof(_financialLaunchRepository));

        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(FinancialLaunchViewModel financialLaunchView)
        {
            var financiallaunch = new FinancialLaunch(
                 financialLaunchView.LaunchMonth, financialLaunchView.UserID, financialLaunchView.ProjectId, financialLaunchView.Hours
                 financialLaunchView.CostValue);
            return Ok();

        }

        [HttpGet]
        public IActionResult Get()
        {
            var financiallaunch = _financialLaunchRepository.Get();
            return Ok();
        }
    }
}
