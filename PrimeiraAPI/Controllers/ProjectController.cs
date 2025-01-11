using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/project")]
    public class ProjectController : Controller
    {
        private readonly IProjectRepository _projectRepository;

        public ProjectController(IProjectRepository _projectRepository)
        {
            _projectRepository = _projectRepository ?? throw new ArgumentException(nameof(_projectRepository));

        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(ProjectViewModel projectView)
        {


            var project = new Project(projectView.Idserial, projectView.Title, projectView.DevelopmentStat, projectView.EstimatedCost, projectView.ApprovedCost, projectView.TotalAccomplished, projectView.TotalAvailable, projectView.Observations, projectView.RequestingArea, projectView.ExpectedStart, projectView.DurationExpected);
            _projectRepository.Add(project);

            return Ok();
        }

        [HttpGet]
        public IActionResult Get()
        {

            var project = _projectRepository.Get();
            return Ok();
        }
    }
}
