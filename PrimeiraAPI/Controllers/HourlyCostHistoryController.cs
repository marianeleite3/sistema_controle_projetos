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

        // Construtor que injeta o repositório
        public HourlyCostHistoryController(HourlyCostHistoryRepository _hourlyCostHistoryRepository)
        {
            _hourlyCostHistoryRepository = _hourlyCostHistoryRepository ?? throw new ArgumentException(nameof(_hourlyCostHistoryRepository));
        }

        // Adicionar um novo HourlyCostHistory
        [HttpPost]
        [Authorize]
        public IActionResult Add(HourlyCostHistoryViewModel hourlyCostHistoryView)
        {
            // Criando o modelo de HourlyCostHistory a partir da ViewModel
            var hourlyCostHistory = new HourlyCostHistory(
                hourlyCostHistoryView.UserId,
                hourlyCostHistoryView.HourlyCost,
                hourlyCostHistoryView.DateBegins,
                hourlyCostHistoryView.DateEnds
            );

            // Salvando o novo HourlyCostHistory no repositório
            _hourlyCostHistoryRepository.Add(hourlyCostHistory);

            return Ok();
        }

        // Obter todos os HourlyCostHistories
        [HttpGet]
        public IActionResult Get()
        {
            var hourlyCostHistories = _hourlyCostHistoryRepository.Get();
            return Ok();
        }


    }
}
