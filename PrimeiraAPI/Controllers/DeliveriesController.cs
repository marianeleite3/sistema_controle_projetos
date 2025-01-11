using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Infra;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/project")]
    public class DeliveriesController: Controller
    {
        private readonly IDeliveriesRepository _deliveriesRepository;

        public DeliveriesController(IDeliveriesRepository _deliveriesRepository)
        {
            _deliveriesRepository = _deliveriesRepository ?? throw new ArgumentException(nameof(_deliveriesRepository)); ;
        }

        [HttpPost]
        [Authorize]
        public IActionResult Add(DeliveriesViewModel deliveriesView)
        {
            var deliveries = new Deliveries(deliveriesView.ProjectCode, deliveriesView.SpecFuncPrevisionStart, deliveriesView.SpecFuncPrevisionEnd, deliveriesView.SpecFuncExecutionStart, deliveriesView.SpecFuncExecutionEnd,
            deliveriesView.ApprovalPrevisionStart, deliveriesView.ApprovalPrevisionEnd, deliveriesView.ApprovalExecutionStart, deliveriesView.ApprovalExecutionEnd, deliveriesView.DevelopmentPrevisionStart, deliveriesView.DevelopmentPrevisionEnd,
            deliveriesView.DevelopmentExecutionStart, deliveriesView.DevelopmentExecutionEnd, deliveriesView.TestTIPrevisionStart, deliveriesView.TestTIPrevisionEnd, deliveriesView.TestTIExecutionStart, deliveriesView.TestTIExecutionEnd,
            deliveriesView.HomologationPrevisionStart, deliveriesView.HomologationPrevisionEnd, deliveriesView.HomologationExecutionStart, deliveriesView.HomologationExecutionEnd, deliveriesView.GoLivePrevisionStart, deliveriesView.GoLivePrevisionEnd,
            deliveriesView.GoLiveExecutionStart, deliveriesView.GoLiveExecutionEnd, deliveriesView.AssistedOperationPrevisionStart, deliveriesView.AssistedOperationPrevisionEnd, deliveriesView.AssistedOperationExecutionStart,
            deliveriesView.AssistedOperationExecutionEnd
                );
            _deliveriesRepository.Add(deliveries);

            return Ok();
            
        }

    }
}
