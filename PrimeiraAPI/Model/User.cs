using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Xml.Linq;

namespace PrimeiraAPI.Model
{
    [Table("EndUser")]
    public class User
    {
        [Key]
        public int IdSerial { get; private set; }
        public string UserCode { get; set; }

        public string FullName { get; set; }

        public string NickName { get; set; }

        public string Origem { get; set; }

        public bool Status { get; set; }

        public double HourlyCost { get; set; }
        public string Responsibility { get; set; }

        public string SecurityKey { get; set; }

        public User(string UserCode, string FullName, string NickName, string Origem, bool Status, double HourlyCost, string Responsibility, string SecurityKey)
        {
            this.UserCode = UserCode;
            this.FullName = FullName ?? throw new ArgumentException(nameof(FullName));
            this.NickName = NickName;
            this.Origem = Origem;
            this.Status = Status;
            this.HourlyCost = HourlyCost;
            this.Responsibility = Responsibility;
            this.SecurityKey = SecurityKey;
            
        }

        public User()
        {
            
        }

    }
}


