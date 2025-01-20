using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;
using PrimeiraAPI.Infra;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/forecastprocess")]
    public class ForecastProcessController : Controller
    {
        private readonly ForecastProcessRepository _forecastProcessRepository;

        // Construtor que injeta o repositório
        public ForecastProcessController(ForecastProcessRepository forecastProcessRepository)
        {
            _forecastProcessRepository = forecastProcessRepository ?? throw new ArgumentException(nameof(forecastProcessRepository));
        }

        // Adicionar um novo ForecastProcess
        [HttpPost]
        [Authorize]
        public IActionResult Add(ForecastProcessViewModel forecastProcessView)
        {
            // Criando o modelo de ForecastProcess a partir da ViewModel
            var forecastProcess = new ForecastProcess(
                forecastProcessView.ProjectId,
                forecastProcessView.ApliedJanuary, forecastProcessView.PrevisionJanuary, forecastProcessView.ExecutionJanuary,
                forecastProcessView.ApliedFebruary, forecastProcessView.PrevisionFebruary, forecastProcessView.ExecutionFebruary,
                forecastProcessView.ApliedMarch, forecastProcessView.PrevisionMarch, forecastProcessView.ExecutionMarch,
                forecastProcessView.ApliedApril, forecastProcessView.PrevisionApril, forecastProcessView.ExecutionApril,
                forecastProcessView.ApliedMay, forecastProcessView.PrevisionMay, forecastProcessView.ExecutionMay,
                forecastProcessView.ApliedJune, forecastProcessView.PrevisionJune, forecastProcessView.ExecutionJune,
                forecastProcessView.ApliedJuly, forecastProcessView.PrevisionJuly, forecastProcessView.ExecutionJuly,
                forecastProcessView.ApliedAugust, forecastProcessView.PrevisionAugust, forecastProcessView.ExecutionAugust,
                forecastProcessView.ApliedSeptember, forecastProcessView.PrevisionSeptember, forecastProcessView.ExecutionSeptember,
                forecastProcessView.ApliedOctober, forecastProcessView.PrevisionOctober, forecastProcessView.ExecutionOctober,
                forecastProcessView.ApliedNovember, forecastProcessView.PrevisionNovember, forecastProcessView.ExecutionNovember,
                forecastProcessView.ApliedDecember, forecastProcessView.PrevisionDecember, forecastProcessView.ExecutionDecember
            );

            // Salvando o novo ForecastProcess no repositório
            _forecastProcessRepository.Add(forecastProcess);

            return Ok();
        }

        // Obter todos os ForecastProcesses
        [HttpGet]
        public IActionResult Get()
        {
            // Obtendo todos os ForecastProcesses
            var forecastProcesses = _forecastProcessRepository.Get();
            return Ok(forecastProcesses);
        }

        [HttpGet("{idSerial}")]
        public IActionResult GetForecastProcessByCode(int idSerial)
        {
            var financiallaunch = _forecastProcessRepository.GetForecastProcessByCode(idSerial);
            if (financiallaunch == null)
            {
                return NotFound();
            }
            return Ok(financiallaunch);
        }

        [HttpDelete("{idSerial}")]
        public IActionResult Delete(int idSerial)
        {
            var financiallaunch = _forecastProcessRepository.GetForecastProcessByCode(idSerial);
            if (financiallaunch == null)
            {
                return NotFound();
            }

            _forecastProcessRepository.Delete(idSerial);
            return Ok();
        }
    }
}
