using Microsoft.EntityFrameworkCore;
using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class ConnectionContext : DbContext
    {
        public DbSet<Employee> Employees { get; set; }

        public DbSet<User> User { get; set; }

        public DbSet<Project> Project { get; set; }

        public DbSet<Deliveries> Deliveries { get; set; }

        public DbSet<FinancialLaunch> FinancialLaunch { get; set; }

        public DbSet<ForecastProcess> ForecastProcess { get; set; }

        public DbSet<HourlyCostHistory> HourlyCostHistory { get; set; }




        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
          => optionsBuilder.UseNpgsql(
            "Host=dpg-cu1gq5jtq21c73bi9st0-a.oregon-postgres.render.com;" +
            "Port=5432;" +
            "Database=employee_sample;" +
            "Username=postgres_sist_controle_projetos;" +
            "Password=9AzWOGyIaSk7br76jLWr6xVK61H3sjc9;");

    }
}
