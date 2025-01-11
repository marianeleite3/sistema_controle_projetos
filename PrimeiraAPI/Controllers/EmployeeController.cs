using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("api/v1/employee")]
    public class EmployeeController : Controller
    {

        private readonly IEmployeeRepository _employeeRepository;

        public EmployeeController(IEmployeeRepository employeeRepository)
        {
            _employeeRepository = employeeRepository ?? throw new ArgumentException(nameof(employeeRepository));
            
        }

        
        [HttpPost]
        [Authorize]
        public IActionResult Add(EmployeeViewModel employeeView)
        {

            var employee = new Employee(employeeView.Name, employeeView.Age);

            _employeeRepository.Add(employee);
            return Ok();
        }

        [HttpGet]
        public IActionResult Get() {

            var employees = _employeeRepository.Get();
            return Ok(); }
    }
}
