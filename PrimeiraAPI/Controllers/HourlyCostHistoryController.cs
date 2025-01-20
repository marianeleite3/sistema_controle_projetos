using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;
using PrimeiraAPI.Infra;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/hourlycosthistory")]
    public class HourlyCostHistoryController : Controller
    {
        private readonly HourlyCostHistoryRepository _hourlyCostHistoryRepository;

        public HourlyCostHistoryController(HourlyCostHistoryRepository hourlyCostHistoryRepository)
        {
            _hourlyCostHistoryRepository = hourlyCostHistoryRepository ?? throw new ArgumentException(nameof(hourlyCostHistoryRepository));
        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(HourlyCostHistoryViewModel hourlyCostHistoryView)
        {
           
            var hourlyCostHistory = new HourlyCostHistory(
                hourlyCostHistoryView.UserId,
                hourlyCostHistoryView.HourlyCost,
                hourlyCostHistoryView.DateBegins,
                hourlyCostHistoryView.DateEnds
            );

            _hourlyCostHistoryRepository.Add(hourlyCostHistory);

            return Ok();
        }

        [HttpGet]
        public IActionResult Get()
        {
            var hourlyCostHistories = _hourlyCostHistoryRepository.Get();
            return Ok();
        }


    }
}
