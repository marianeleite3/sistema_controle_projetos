using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("FinancialLaunch")]
    public class FinancialLaunch
    {
        [Key]
        public int IdSerial { get; set; }

        public string LaunchMonth { get; set; }
        public string UserID { get; set; }
        public string ProjectId { get; set; }
        public int Hours { get; set; }

        public double CostValue { get; set; }

        public FinancialLaunch(string LaunchMonth, string UserID, string ProjectId , int Hours,
           double CostValue) { 
            this.LaunchMonth = LaunchMonth;
            this.UserID = UserID;
            this.ProjectId = ProjectId;
            this.CostValue = CostValue;

        }

        public FinancialLaunch() {

        }



    }
}
