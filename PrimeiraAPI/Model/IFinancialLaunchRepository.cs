namespace PrimeiraAPI.Model
{
    public interface IFinancialLaunchRepository
    {
        void Add(FinancialLaunch financialLaunch);

        List<FinancialLaunch> Get();

        FinancialLaunch GetFinancialLaunchByCode(int idSerial);

        void Delete(int idSerial);
    }
}
