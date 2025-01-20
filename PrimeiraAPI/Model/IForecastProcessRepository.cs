namespace PrimeiraAPI.Model
{
    public interface IForecastProcessRepository
    {
        void Add(ForecastProcess forecastProcess);

        List<ForecastProcess> Get();

        ForecastProcess GetForecastProcessByCode(int idSerial);

        void Delete(int idSerial);
    }
}
