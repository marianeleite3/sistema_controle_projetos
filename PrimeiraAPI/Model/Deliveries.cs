using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using static System.Net.Mime.MediaTypeNames;

namespace PrimeiraAPI.Model
{
    [Table("Project")]
    public class Deliveries
    {
        [Key]
        public int DeliveryId { get; set; }

        public string ProjectCode { get; set; }


        public string SpecFuncPrevisionStart { get; set; }
        public string SpecFuncPrevisionEnd { get; set; }
        public string SpecFuncExecutionStart { get; set; }
        public string SpecFuncExecutionEnd { get; set; }


        public string ApprovalPrevisionStart { get; set; }
        public string ApprovalPrevisionEnd { get; set; }
        public string ApprovalExecutionStart { get; set; }

        public string ApprovalExecutionEnd { get; set; }

        public string DevelopmentPrevisionStart { get; set; }
        public string DevelopmentPrevisionEnd { get; set; }
        public string DevelopmentExecutionStart { get; set; }
        public string DevelopmentExecutionEnd { get; set; }

        public string TestTIPrevisionStart { get; set; }
        public string TestTIPrevisionEnd { get; set; }
        public string TestTIExecutionStart { get; set; }
        public string TestTIExecutionEnd { get; set; }

        public string HomologationPrevisionStart { get; set; }
        public string HomologationPrevisionEnd { get; set; }
        public string HomologationExecutionStart { get; set; }
        public string HomologationExecutionEnd { get; set; }

        public string GoLivePrevisionStart { get; set; }
        public string GoLivePrevisionEnd { get; set; }
        public string GoLiveExecutionStart { get; set; }
        public string GoLiveExecutionEnd { get; set; }


        public string AssistedOperationPrevisionStart { get; set; }
        public string AssistedOperationPrevisionEnd { get; set; }
        public string AssistedOperationExecutionStart { get; set; }
        public string AssistedOperationExecutionEnd { get; set; }

        public Deliveries(string ProjectCode, string SpecFuncPrevisionStart, string SpecFuncPrevisionEnd, string SpecFuncExecutionStart, string SpecFuncExecutionEnd,
        string ApprovalPrevisionStart, string ApprovalPrevisionEnd, string ApprovalExecutionStart, string ApprovalExecutionEnd, string DevelopmentPrevisionStart, string DevelopmentPrevisionEnd,
        string DevelopmentExecutionStart, string DevelopmentExecutionEnd, string TestTIPrevisionStart, string TestTIPrevisionEnd, string TestTIExecutionStart, string TestTIExecutionEnd,
        string HomologationPrevisionStart, string HomologationPrevisionEnd, string HomologationExecutionStart, string HomologationExecutionEnd, string GoLivePrevisionStart, string GoLivePrevisionEnd,
        string GoLiveExecutionStart, string GoLiveExecutionEnd, string AssistedOperationPrevisionStart, string AssistedOperationPrevisionEnd, string AssistedOperationExecutionStart,
        string AssistedOperationExecutionEnd)
        {
            this.ProjectCode = ProjectCode;
            this.SpecFuncPrevisionStart = SpecFuncPrevisionStart;
            this.SpecFuncPrevisionEnd = SpecFuncPrevisionEnd;
            this.SpecFuncExecutionStart = SpecFuncExecutionStart;
            this.SpecFuncExecutionEnd = SpecFuncExecutionEnd;
            this.ApprovalPrevisionStart = ApprovalPrevisionStart;
            this.ApprovalPrevisionEnd = ApprovalPrevisionEnd;
            this.ApprovalExecutionStart = ApprovalExecutionStart;
            this.ApprovalExecutionEnd = ApprovalExecutionEnd;
            this.DevelopmentPrevisionStart = DevelopmentPrevisionStart;
            this.DevelopmentPrevisionEnd = DevelopmentPrevisionEnd;
            this.DevelopmentExecutionStart = DevelopmentExecutionStart;
            this.DevelopmentExecutionEnd = DevelopmentExecutionEnd;
            this.TestTIPrevisionStart = TestTIPrevisionStart;
            this.TestTIPrevisionEnd = TestTIPrevisionEnd;
            this.TestTIExecutionStart = TestTIExecutionStart;
            this.TestTIExecutionEnd = TestTIExecutionEnd;
            this.HomologationPrevisionStart = HomologationPrevisionStart;
            this.HomologationPrevisionEnd = HomologationPrevisionEnd;
            this.HomologationExecutionStart = HomologationExecutionStart;
            this.HomologationExecutionEnd = HomologationExecutionEnd;
            this.GoLivePrevisionStart = GoLivePrevisionStart;
            this.GoLivePrevisionEnd = GoLivePrevisionEnd;
            this.GoLiveExecutionStart = GoLiveExecutionStart;
            this.GoLiveExecutionEnd = GoLiveExecutionEnd;
            this.AssistedOperationPrevisionStart = AssistedOperationPrevisionStart;
            this.AssistedOperationPrevisionEnd = AssistedOperationPrevisionEnd;
            this.AssistedOperationExecutionStart = AssistedOperationExecutionStart;
            this.AssistedOperationExecutionEnd = AssistedOperationExecutionEnd;
        }



        public Deliveries() { }

    }
}
