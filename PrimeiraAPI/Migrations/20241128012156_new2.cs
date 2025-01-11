using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PrimeiraAPI.Migrations
{
    /// <inheritdoc />
    public partial class new2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Project",
                columns: table => new
                {
                    ProjectCode = table.Column<string>(type: "text", nullable: false),
                    Idserial = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    DevelopmentStat = table.Column<string>(type: "text", nullable: false),
                    EstimatedCost = table.Column<double>(type: "double precision", nullable: false),
                    ApprovedCost = table.Column<double>(type: "double precision", nullable: false),
                    TotalAccomplished = table.Column<double>(type: "double precision", nullable: false),
                    TotalAvailable = table.Column<double>(type: "double precision", nullable: false),
                    Observations = table.Column<string>(type: "text", nullable: false),
                    RequestingArea = table.Column<string>(type: "text", nullable: false),
                    ExpectedStart = table.Column<string>(type: "text", nullable: false),
                    DurationExpected = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Project", x => x.ProjectCode);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Project");
        }
    }
}
