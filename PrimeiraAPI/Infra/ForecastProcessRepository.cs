using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class ForecastProcessRepository : IForecastProcessRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();

        // Adicionar um novo processo de previsão
        public void Add(ForecastProcess forecastProcess)
        {
            _context.ForecastProcess.Add(forecastProcess);
            _context.SaveChanges();
        }

        // Obter todos os processos de previsão
        public List<ForecastProcess> Get()
        {
            return _context.ForecastProcess.ToList();
        }

    }
}
