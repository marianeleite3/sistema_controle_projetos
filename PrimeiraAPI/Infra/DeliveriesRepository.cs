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

        public List<Deliveries> Get()
        {
            return _context.Deliveries.ToList();
        }
    }
}
