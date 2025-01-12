using PrimeiraAPI.Model;
using System.Collections.Generic;
using System.Linq;

namespace PrimeiraAPI.Infra
{
    public class UserProjectRepository : IUserProjectRepository
    {
        private readonly ConnectionContext _context = new ConnectionContext();

        // Adicionar um novo UserProject
        public void Add(UserProject userProject)
        {
            _context.UserProject.Add(userProject);
            _context.SaveChanges();
        }

        // Obter todos os UserProjects
        public List<UserProject> Get()
        {
            return _context.UserProject.ToList();
        }

        // Obter um UserProject por UserCode e ProjectCode
        public UserProject GetByUserCodeAndProjectCode(string userCode, string projectCode)
        {
            return _context.UserProject
                .FirstOrDefault(up => up.UserCode == userCode && up.ProjectCode == projectCode);
        }

        // Deletar um UserProject
        public void Delete(string userCode, string projectCode)
        {
            var userProject = _context.UserProject
                .FirstOrDefault(up => up.UserCode == userCode && up.ProjectCode == projectCode);
            if (userProject != null)
            {
                _context.UserProject.Remove(userProject);
                _context.SaveChanges();
            }
        }
    }
}
