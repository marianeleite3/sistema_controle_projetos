using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("UserProject")]
    public class UserProject
    {
        [Key]
        [Column(Order = 1)] // Definindo a chave composta
        [StringLength(8)]
        public string UserCode { get; set; }

        [Key]
        [Column(Order = 2)] // Definindo a chave composta
        [StringLength(12)]
        public string ProjectCode { get; set; }

        // Construtor para inicialização
        public UserProject(string UserCode, string ProjectCode)
        {
            UserCode = UserCode;
            ProjectCode = ProjectCode;
        }

        // Construtor vazio para o EF Core
        public UserProject() { }
    }
}
