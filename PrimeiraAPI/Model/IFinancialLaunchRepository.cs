namespace PrimeiraAPI.Model
{
    public interface IFinancialLaunchRepository
    {
        void Add(FinancialLaunch financialLaunch);

        List<FinancialLaunch> Get();
    }
}
