using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace PrimeiraAPI.Migrations
{
    /// <inheritdoc />
    public partial class new1901 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Deliveries",
                columns: table => new
                {
                    DeliveryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ProjectCode = table.Column<string>(type: "text", nullable: false),
                    SpecFuncPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    SpecFuncPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    SpecFuncExecutionStart = table.Column<string>(type: "text", nullable: false),
                    SpecFuncExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    ApprovalPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    ApprovalPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    ApprovalExecutionStart = table.Column<string>(type: "text", nullable: false),
                    ApprovalExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    DevelopmentPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    DevelopmentPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    DevelopmentExecutionStart = table.Column<string>(type: "text", nullable: false),
                    DevelopmentExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    TestTIPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    TestTIPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    TestTIExecutionStart = table.Column<string>(type: "text", nullable: false),
                    TestTIExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    HomologationPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    HomologationPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    HomologationExecutionStart = table.Column<string>(type: "text", nullable: false),
                    HomologationExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    GoLivePrevisionStart = table.Column<string>(type: "text", nullable: false),
                    GoLivePrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    GoLiveExecutionStart = table.Column<string>(type: "text", nullable: false),
                    GoLiveExecutionEnd = table.Column<string>(type: "text", nullable: false),
                    AssistedOperationPrevisionStart = table.Column<string>(type: "text", nullable: false),
                    AssistedOperationPrevisionEnd = table.Column<string>(type: "text", nullable: false),
                    AssistedOperationExecutionStart = table.Column<string>(type: "text", nullable: false),
                    AssistedOperationExecutionEnd = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Deliveries", x => x.DeliveryId);
                    table.ForeignKey(
                        name: "FK_Deliveries_Project_ProjectCode",
                        column: x => x.ProjectCode,
                        principalTable: "Project",
                        principalColumn: "ProjectCode",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "FinancialLaunch",
                columns: table => new
                {
                    IdSerial = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    LaunchMonth = table.Column<string>(type: "text", nullable: false),
                    UserID = table.Column<string>(type: "text", nullable: false),
                    ProjectId = table.Column<string>(type: "text", nullable: false),
                    Hours = table.Column<int>(type: "integer", nullable: false),
                    CostValue = table.Column<double>(type: "double precision", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinancialLaunch", x => x.IdSerial);
                });

            migrationBuilder.CreateTable(
                name: "ForecastProcess",
                columns: table => new
                {
                    IDSerial = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ProjectId = table.Column<string>(type: "text", nullable: false),
                    ApliedJanuary = table.Column<string>(type: "text", nullable: false),
                    PrevisionJanuary = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionJanuary = table.Column<double>(type: "double precision", nullable: false),
                    ApliedFebruary = table.Column<string>(type: "text", nullable: false),
                    PrevisionFebruary = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionFebruary = table.Column<double>(type: "double precision", nullable: false),
                    ApliedMarch = table.Column<string>(type: "text", nullable: false),
                    PrevisionMarch = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionMarch = table.Column<double>(type: "double precision", nullable: false),
                    ApliedApril = table.Column<string>(type: "text", nullable: false),
                    PrevisionApril = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionApril = table.Column<double>(type: "double precision", nullable: false),
                    ApliedMay = table.Column<string>(type: "text", nullable: false),
                    PrevisionMay = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionMay = table.Column<double>(type: "double precision", nullable: false),
                    ApliedJune = table.Column<string>(type: "text", nullable: false),
                    PrevisionJune = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionJune = table.Column<double>(type: "double precision", nullable: false),
                    ApliedJuly = table.Column<string>(type: "text", nullable: false),
                    PrevisionJuly = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionJuly = table.Column<double>(type: "double precision", nullable: false),
                    ApliedAugust = table.Column<string>(type: "text", nullable: false),
                    PrevisionAugust = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionAugust = table.Column<double>(type: "double precision", nullable: false),
                    ApliedSeptember = table.Column<string>(type: "text", nullable: false),
                    PrevisionSeptember = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionSeptember = table.Column<double>(type: "double precision", nullable: false),
                    ApliedOctober = table.Column<string>(type: "text", nullable: false),
                    PrevisionOctober = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionOctober = table.Column<double>(type: "double precision", nullable: false),
                    ApliedNovember = table.Column<string>(type: "text", nullable: false),
                    PrevisionNovember = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionNovember = table.Column<double>(type: "double precision", nullable: false),
                    ApliedDecember = table.Column<string>(type: "text", nullable: false),
                    PrevisionDecember = table.Column<double>(type: "double precision", nullable: false),
                    ExecutionDecember = table.Column<double>(type: "double precision", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ForecastProcess", x => x.IDSerial);
                });

            migrationBuilder.CreateTable(
                name: "HourlyCostHistory",
                columns: table => new
                {
                    Identifier = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    HourlyCost = table.Column<decimal>(type: "numeric(10,2)", nullable: false),
                    DateBegins = table.Column<string>(type: "text", nullable: false),
                    DateEnds = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_HourlyCostHistory", x => x.Identifier);
                });

            migrationBuilder.CreateTable(
                name: "UserProject",
                columns: table => new
                {
                    UserCode = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    ProjectCode = table.Column<string>(type: "character varying(12)", maxLength: 12, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserProject", x => new { x.UserCode, x.ProjectCode });
                });

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_ProjectCode",
                table: "Deliveries",
                column: "ProjectCode");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Deliveries");

            migrationBuilder.DropTable(
                name: "FinancialLaunch");

            migrationBuilder.DropTable(
                name: "ForecastProcess");

            migrationBuilder.DropTable(
                name: "HourlyCostHistory");

            migrationBuilder.DropTable(
                name: "UserProject");
        }
    }
}
