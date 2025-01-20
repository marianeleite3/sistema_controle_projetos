using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class DeliveriesRepository : IDeliveriesRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();
        public void Add(Deliveries deliveries)
        {
            _context.Deliveries.Add(deliveries);
            _context.SaveChanges();
        }

        public void Delete(int deliveryId)
        {
            var deliveries = _context.Deliveries
                .FirstOrDefault(up => up.DeliveryId == deliveryId);
            if (deliveries != null)
            {
                _context.Deliveries.Remove(deliveries);
                _context.SaveChanges();
            }
        }

        public List<Deliveries> Get()
        {
            return _context.Deliveries.ToList();
        }

        public Deliveries GetDeliveryByCode(int deliveryId)
        {
            return _context.Deliveries
               .FirstOrDefault(up => up.DeliveryId == deliveryId);
        }
    }
}
