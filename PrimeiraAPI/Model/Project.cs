using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("Project")]
    public class Project
    {
        [Key]
        public string ProjectCode { get; set; }  

        public int Idserial { get; set; }

        public string Title { get; set; }

        public string DevelopmentStat { get; set; }

        public double EstimatedCost { get; set; }

        public double ApprovedCost { get; set; }

        public double TotalAccomplished { get; set; }

        public double TotalAvailable { get; set; }

        public string Observations { get; set; }

        public string RequestingArea { get; set; }

        public string ExpectedStart { get; set; }


        public int DurationExpected { get; set; }

        public Project(int Idserial, string Title, string DevelopmentStat, double EstimatedCost, 
            double ApprovedCost, double TotalAccomplished, double TotalAvailable, string Observations, string RequestingArea, string ExpectedStart, int DurationExpected)
        {
            this.Idserial = Idserial;
            this.Title = Title;
            this.DevelopmentStat = DevelopmentStat;
            this.EstimatedCost = EstimatedCost;
            this.ApprovedCost = ApprovedCost;
            this.TotalAccomplished = TotalAccomplished;
            this.TotalAvailable = TotalAvailable;
            this.Observations = Observations;
            this.RequestingArea = RequestingArea;
            this.ExpectedStart = ExpectedStart;
            this.DurationExpected = DurationExpected;


        }

        public Project()
        {
            
        }
    }
}
