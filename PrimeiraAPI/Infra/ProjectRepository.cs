using PrimeiraAPI.Model;

namespace PrimeiraAPI.Infra
{
    public class ProjectRepository : IProjectRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();
        public void Add(Project project)
        {
            _context.Project.Add(project);
            _context.SaveChanges();
        }

        public List<Project> Get()
        {
            return _context.Project.ToList();
        }
    }
}
