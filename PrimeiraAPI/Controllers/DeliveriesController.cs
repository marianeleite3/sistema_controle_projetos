﻿using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrimeiraAPI.Infra;
using PrimeiraAPI.Model;
using PrimeiraAPI.ViewModel;

namespace PrimeiraAPI.Controllers
{
    [ApiController]
    [Route("/api/v1/deliveries")]
    public class DeliveriesController: Controller
    {
        private readonly IDeliveriesRepository _deliveriesRepository;

        public DeliveriesController(IDeliveriesRepository deliveriesRepository)
        {
            _deliveriesRepository = deliveriesRepository ?? throw new ArgumentException(nameof(deliveriesRepository)); ;
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


        [HttpGet]
        public IActionResult Get()
        {

            var deliveries = _deliveriesRepository.Get();
            return Ok(deliveries);
        }

        [HttpGet("{deliveryId}")]
        public IActionResult GetDeliveryByCode(int deliveryId)
        {
            var deliveries = _deliveriesRepository.GetDeliveryByCode(deliveryId);
            if (deliveries == null)
            {
                return NotFound();
            }
            return Ok(deliveries);
        }

        [HttpDelete("{deliveryId}")]
        public IActionResult Delete(int deliveryId)
        {
            var deliveries = _deliveriesRepository.GetDeliveryByCode(deliveryId);
            if (deliveries == null)
            {
                return NotFound();
            }

            _deliveriesRepository.Delete(deliveryId);
            return Ok();
        }

    }
}
