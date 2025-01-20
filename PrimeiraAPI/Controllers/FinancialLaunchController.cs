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

        public FinancialLaunchController(IFinancialLaunchRepository financialLaunchRepository)
        {
            _financialLaunchRepository = financialLaunchRepository ?? throw new ArgumentException(nameof(financialLaunchRepository));

        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(FinancialLaunchViewModel financialLaunchView)
        {
            var financiallaunch = new FinancialLaunch(
                 financialLaunchView.LaunchMonth, financialLaunchView.UserID, financialLaunchView.ProjectId, financialLaunchView.Hours,
                 financialLaunchView.CostValue);
            return Ok();

        }

        [HttpGet]
        public IActionResult Get()
        {
            var financiallaunch = _financialLaunchRepository.Get();
            return Ok(financiallaunch);
        }


        [HttpGet("{idSerial}")]
        public IActionResult GetProjectByCode(int idSerial)
        {
            var financiallaunch = _financialLaunchRepository.GetFinancialLaunchByCode(idSerial);
            if (financiallaunch == null)
            {
                return NotFound();
            }
            return Ok(financiallaunch);
        }

        [HttpDelete("{idSerial}")]
        public IActionResult Delete(int idSerial)
        {
            var financiallaunch = _financialLaunchRepository.GetFinancialLaunchByCode(idSerial);
            if (financiallaunch == null)
            {
                return NotFound();
            }

            _financialLaunchRepository.Delete(idSerial);
            return Ok();
        }
    }
}
