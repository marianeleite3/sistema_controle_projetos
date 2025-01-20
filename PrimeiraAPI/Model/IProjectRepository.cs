namespace PrimeiraAPI.Model
{
    public interface IProjectRepository
    {
        void Add(Project project);

        List<Project> Get();

        Project GetProjectByCode(string projectCode);

        void Delete(string projectCode);
    }
}
