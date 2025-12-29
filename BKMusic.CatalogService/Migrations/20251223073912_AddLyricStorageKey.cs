using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BKMusic.CatalogService.Migrations
{
    /// <inheritdoc />
    public partial class AddLyricStorageKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "LyricStorageKey",
                table: "Songs",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LyricStorageKey",
                table: "Songs");
        }
    }
}
