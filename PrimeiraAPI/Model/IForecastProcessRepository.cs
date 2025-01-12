namespace PrimeiraAPI.Model
{
    public interface IForecastProcessRepository
    {
        void Add(ForecastProcess forecastProcess);

        List<ForecastProcess> Get();
    }
}
