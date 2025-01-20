using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("ForecastProcess")]
    public class ForecastProcess
    {
        [Key]
        public int IdSerial { get; set; }

        public string ProjectId { get; set; }

        // January
        public string ApliedJanuary { get; set; }
        public double PrevisionJanuary { get; set; }
        public double ExecutionJanuary { get; set; }

        // February
        public string ApliedFebruary { get; set; }
        public double PrevisionFebruary { get; set; }
        public double ExecutionFebruary { get; set; }

        // March
        public string ApliedMarch { get; set; }
        public double PrevisionMarch { get; set; }
        public double ExecutionMarch { get; set; }

        // April
        public string ApliedApril { get; set; }
        public double PrevisionApril { get; set; }
        public double ExecutionApril { get; set; }

        // May
        public string ApliedMay { get; set; }
        public double PrevisionMay { get; set; }
        public double ExecutionMay { get; set; }

        // June
        public string ApliedJune { get; set; }
        public double PrevisionJune { get; set; }
        public double ExecutionJune { get; set; }

        // July
        public string ApliedJuly { get; set; }
        public double PrevisionJuly { get; set; }
        public double ExecutionJuly { get; set; }

        // August
        public string ApliedAugust { get; set; }
        public double PrevisionAugust { get; set; }
        public double ExecutionAugust { get; set; }

        // September
        public string ApliedSeptember { get; set; }
        public double PrevisionSeptember { get; set; }
        public double ExecutionSeptember { get; set; }

        // October
        public string ApliedOctober { get; set; }
        public double PrevisionOctober { get; set; }
        public double ExecutionOctober { get; set; }

        // November
        public string ApliedNovember { get; set; }
        public double PrevisionNovember { get; set; }
        public double ExecutionNovember { get; set; }

        // December
        public string ApliedDecember { get; set; }
        public double PrevisionDecember { get; set; }
        public double ExecutionDecember { get; set; }

        // Constructor to initialize all properties
        public ForecastProcess(string ProjectId, string ApliedJanuary, double PrevisionJanuary, double ExecutionJanuary,
            string ApliedFebruary, double PrevisionFebruary, double ExecutionFebruary, string ApliedMarch, double PrevisionMarch, double ExecutionMarch,
            string ApliedApril, double PrevisionApril, double ExecutionApril, string ApliedMay, double PrevisionMay, double ExecutionMay,
            string ApliedJune, double PrevisionJune, double ExecutionJune, string ApliedJuly, double PrevisionJuly, double ExecutionJuly,
            string ApliedAugust, double PrevisionAugust, double ExecutionAugust, string ApliedSeptember, double PrevisionSeptember, double ExecutionSeptember,
            string ApliedOctober, double PrevisionOctober, double ExecutionOctober, string ApliedNovember, double PrevisionNovember, double ExecutionNovember,
            string ApliedDecember, double PrevisionDecember, double ExecutionDecember)
        {
          
            this.ProjectId = ProjectId;
            this.ApliedJanuary = ApliedJanuary;
            this.PrevisionJanuary = PrevisionJanuary;
            this.ExecutionJanuary = ExecutionJanuary;
            this.ApliedFebruary = ApliedFebruary;
            this.PrevisionFebruary = PrevisionFebruary;
            this.ExecutionFebruary = ExecutionFebruary;
            this.ApliedMarch = ApliedMarch;
            this.PrevisionMarch = PrevisionMarch;
            this.ExecutionMarch = ExecutionMarch;
            this.ApliedApril = ApliedApril;
            this.PrevisionApril = PrevisionApril;
            this.ExecutionApril = ExecutionApril;
            this.ApliedMay = ApliedMay;
            this.PrevisionMay = PrevisionMay;
            this.ExecutionMay = ExecutionMay;
            this.ApliedJune = ApliedJune;
            this.PrevisionJune = PrevisionJune;
            this.ExecutionJune = ExecutionJune;
            this.ApliedJuly = ApliedJuly;
            this.PrevisionJuly = PrevisionJuly;
            this.ExecutionJuly = ExecutionJuly;
            this.ApliedAugust = ApliedAugust;
            this.PrevisionAugust = PrevisionAugust;
            this.ExecutionAugust = ExecutionAugust;
            this.ApliedSeptember = ApliedSeptember;
            this.PrevisionSeptember = PrevisionSeptember;
            this.ExecutionSeptember = ExecutionSeptember;
            this.ApliedOctober = ApliedOctober;
            this.PrevisionOctober = PrevisionOctober;
            this.ExecutionOctober = ExecutionOctober;
            this.ApliedNovember = ApliedNovember;
            this.PrevisionNovember = PrevisionNovember;
            this.ExecutionNovember = ExecutionNovember;
            this.ApliedDecember = ApliedDecember;
            this.PrevisionDecember = PrevisionDecember;
            this.ExecutionDecember = ExecutionDecember;
        }

        // Default constructor
        public ForecastProcess()
        {
        }
    }
}
