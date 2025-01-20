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

        public void Delete(string projectCode)
        {
            var project = _context.Project
                .FirstOrDefault(up => up.ProjectCode == projectCode);
            if (project != null)
            {
                _context.Project.Remove(project);
                _context.SaveChanges();
            }
        }

        public List<Project> Get()
        {
            return _context.Project.ToList();
        }

        public Project GetProjectByCode(string projectCode)
        {
            return _context.Project
                .FirstOrDefault(up =>  up.ProjectCode == projectCode);
        }
    }
}
