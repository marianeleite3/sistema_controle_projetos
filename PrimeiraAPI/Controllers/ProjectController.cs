using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Infra;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/project")]
    public class ProjectController : Controller
    {
        private readonly IProjectRepository _projectRepository;

        public ProjectController(IProjectRepository projectRepository)
        {
            _projectRepository = projectRepository ?? throw new ArgumentException(nameof(projectRepository));

        }

        /*[HttpPost]
        [Authorize]
        public IActionResult Add([FromBody] Project project)
        {
            // Validate project if needed
            if (project == null)
            {
                return BadRequest("Project data is required.");
            }

            // You don't need to manually map from a ViewModel anymore
            _projectRepository.Add(project);

            return Ok();
        }*/

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
            return Ok(project);
        }

        [HttpGet("{projectCode}")]
        public IActionResult GetProjectByCode(string projectCode)
        {
            var project = _projectRepository.GetProjectByCode(projectCode);
            if (project == null)
            {
                return NotFound();
            }
            return Ok(project);
        }

        [HttpDelete("{projectCode}")]
        public IActionResult Delete(string projectCode) {
            var project = _projectRepository.GetProjectByCode(projectCode);
            if (project == null)
            {
                return NotFound();
            }

            _projectRepository.Delete(projectCode);
            return Ok();
        }
    }
}

