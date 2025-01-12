using PrimeiraAPI.Model;
using System.Collections.Generic;

namespace PrimeiraAPI.Model
{
    public interface IUserProjectRepository
    {
        void Add(UserProject userProject);
        List<UserProject> Get();
        UserProject GetByUserCodeAndProjectCode(string userCode, string projectCode);
        void Delete(string userCode, string projectCode);
    }
}
