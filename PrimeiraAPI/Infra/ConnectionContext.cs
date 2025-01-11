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




        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
          => optionsBuilder.UseNpgsql(
              "Server=localhost;" +
              "Port=5432;Database=employee_sample;" +
              "User Id=postgres;" +
              "Password=postgres;");

    }
}
