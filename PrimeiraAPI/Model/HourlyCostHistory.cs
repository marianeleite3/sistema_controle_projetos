using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PrimeiraAPI.Model
{
    [Table("HourlyCostHistory")]
    public class HourlyCostHistory
    {
        [Key]
        public int Identifier { get; set; }

        [Required]
        [StringLength(8)]
        public string UserId { get; set; }

        [Required]
        [Column(TypeName = "DECIMAL(10, 2)")]
        public decimal HourlyCost { get; set; }

        [Required]
        public string DateBegins { get; set; }

        public string? DateEnds { get; set; }

        public HourlyCostHistory( string UserId, decimal HourlyCost, string DateBegins, string DateEnds)
        {
            UserId = UserId;
            HourlyCost = HourlyCost;
            DateBegins = DateBegins;
            DateEnds = DateEnds;
        }

        public HourlyCostHistory() { }
    }
}
