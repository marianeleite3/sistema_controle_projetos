using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class FinancialLaunchRepository : IFinancialLaunchRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();
        public void Add(FinancialLaunch financialLaunch)
        {
            _context.FinancialLaunch.Add(financialLaunch);
            _context.SaveChanges();
        }

        public List<FinancialLaunch> Get()
        {
            return _context.FinancialLaunch.ToList();
        }
    }
}
