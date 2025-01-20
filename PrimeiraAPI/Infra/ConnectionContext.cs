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

        public DbSet<UserProject> UserProject { get; set; }




        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
          => optionsBuilder.UseNpgsql(
            "Host=dpg-cu1gq5jtq21c73bi9st0-a.oregon-postgres.render.com;" +
            "Port=5432;" +
            "Database=employee_sample;" +
            "Username=postgres_sist_controle_projetos;" +
            "Password=9AzWOGyIaSk7br76jLWr6xVK61H3sjc9;");


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configure composite primary key for UserProject
            modelBuilder.Entity<UserProject>()
                .HasKey(up => new { up.UserCode, up.ProjectCode });

            // Configure the foreign key relationship between Deliveries and Project
            modelBuilder.Entity<Deliveries>()
                .HasOne<Project>() // Deliveries has one Project
                .WithMany() // Project can have many Deliveries
                .HasForeignKey(d => d.ProjectCode) // Foreign key on ProjectCode in Deliveries
                .OnDelete(DeleteBehavior.Restrict); // Prevent cascading delete, adjust behavior as needed

            // Optionally, configure other relationships or settings as needed
        }

    }
}
