using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;
using PrimeiraAPI.Infra;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/userproject")]
    public class UserProjectController : Controller
    {
        private readonly IUserProjectRepository _userProjectRepository;

        // Construtor que injeta o repositório
        public UserProjectController(IUserProjectRepository _userProjectRepository)
        {
            _userProjectRepository = _userProjectRepository ?? throw new ArgumentException(nameof(_userProjectRepository));
        }

        // Adicionar um novo UserProject
        [HttpPost]
        [Authorize]
        public IActionResult Add(UserProjectViewModel userProjectView)
        {
            var userProject = new UserProject(userProjectView.UserCode, userProjectView.ProjectCode);
            _userProjectRepository.Add(userProject);

            return Ok();
        }

        // Obter todos os UserProjects
        [HttpGet]
        public IActionResult Get()
        {
            var userProjects = _userProjectRepository.Get();
            return Ok(userProjects);
        }

        // Obter um UserProject específico por UserCode e ProjectCode
        [HttpGet("{userCode}/{projectCode}")]
        public IActionResult GetByUserCodeAndProjectCode(string userCode, string projectCode)
        {
            var userProject = _userProjectRepository.GetByUserCodeAndProjectCode(userCode, projectCode);
            if (userProject == null)
            {
                return NotFound();
            }
            return Ok(userProject);
        }

        // Deletar um UserProject
        [HttpDelete("{userCode}/{projectCode}")]
        [Authorize]
        public IActionResult Delete(string userCode, string projectCode)
        {
            var userProject = _userProjectRepository.GetByUserCodeAndProjectCode(userCode, projectCode);
            if (userProject == null)
            {
                return NotFound();
            }

            _userProjectRepository.Delete(userCode, projectCode);
            return Ok();
        }
    }
}
