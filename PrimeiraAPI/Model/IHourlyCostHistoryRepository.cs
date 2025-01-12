namespace PrimeiraAPI.Model
{
    public interface IHourlyCostHistoryRepository
    {
        void Add(HourlyCostHistory hourlyCostHistory);
        List<HourlyCostHistory> Get();
    }
}
