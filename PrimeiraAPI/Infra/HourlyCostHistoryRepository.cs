using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class HourlyCostHistoryRepository : IHourlyCostHistoryRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();

        // Adicionar um novo HourlyCostHistory
        public void Add(HourlyCostHistory hourlyCostHistory)
        {
            _context.HourlyCostHistory.Add(hourlyCostHistory);
            _context.SaveChanges();
        }

        // Obter todos os HourlyCostHistories
        public List<HourlyCostHistory> Get()
        {
            return _context.HourlyCostHistory.ToList();
        }

    }
}
