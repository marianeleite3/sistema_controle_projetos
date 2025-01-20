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

        public void Delete(int idSerial)
        {
            var financiallaunch = _context.FinancialLaunch
                .FirstOrDefault(up => up.IdSerial == idSerial);
            if (financiallaunch != null)
            {
                _context.FinancialLaunch.Remove(financiallaunch);
                _context.SaveChanges();
            }
        }

        public List<FinancialLaunch> Get()
        {
            return _context.FinancialLaunch.ToList();
        }

        public FinancialLaunch GetFinancialLaunchByCode(int idSerial)
        {
            return _context.FinancialLaunch
                .FirstOrDefault(up => up.IdSerial == idSerial);
        }

  
    }
}
