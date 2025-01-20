using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("UserProject")]
    public class UserProject
    {
        [StringLength(8)]
        public string UserCode { get; set; }

        [StringLength(12)]
        public string ProjectCode { get; set; }

        // Construtor para inicialização
        public UserProject(string UserCode, string ProjectCode)
        {
            this.UserCode = UserCode;
            this.ProjectCode = ProjectCode;
        }

        // Construtor vazio para o EF Core
        public UserProject() { }
    }
}
