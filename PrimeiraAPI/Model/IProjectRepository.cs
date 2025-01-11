namespace PrimeiraAPI.Model
{
    public interface IProjectRepository
    {
        void Add(Project project);

        List<Project> Get();
    }
}
