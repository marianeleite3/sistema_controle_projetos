﻿// <auto-generated />
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;
using PrimeiraAPI.Infra;

#nullable disable

namespace PrimeiraAPI.Migrations
{
    [DbContext(typeof(ConnectionContext))]
    [Migration("20241128012156_new2")]
    partial class new2
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "7.0.0")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("PrimeiraAPI.Model.Employee", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("id"));

                    b.Property<int>("age")
                        .HasColumnType("integer");

                    b.Property<string>("name")
                        .IsRequired()
                        .HasColumnType("text");

                    b.HasKey("id");

                    b.ToTable("employee");
                });

            modelBuilder.Entity("PrimeiraAPI.Model.Project", b =>
                {
                    b.Property<string>("ProjectCode")
                        .HasColumnType("text");

                    b.Property<double>("ApprovedCost")
                        .HasColumnType("double precision");

                    b.Property<string>("DevelopmentStat")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<int>("DurationExpected")
                        .HasColumnType("integer");

                    b.Property<double>("EstimatedCost")
                        .HasColumnType("double precision");

                    b.Property<string>("ExpectedStart")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<int>("Idserial")
                        .HasColumnType("integer");

                    b.Property<string>("Observations")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("RequestingArea")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<double>("TotalAccomplished")
                        .HasColumnType("double precision");

                    b.Property<double>("TotalAvailable")
                        .HasColumnType("double precision");

                    b.HasKey("ProjectCode");

                    b.ToTable("Project");
                });

            modelBuilder.Entity("PrimeiraAPI.Model.User", b =>
                {
                    b.Property<int>("IdSerial")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("IdSerial"));

                    b.Property<string>("FullName")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<double>("HourlyCost")
                        .HasColumnType("double precision");

                    b.Property<string>("NickName")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Origem")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Responsibility")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("SecurityKey")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<bool>("Status")
                        .HasColumnType("boolean");

                    b.Property<string>("UserCode")
                        .IsRequired()
                        .HasColumnType("text");

                    b.HasKey("IdSerial");

                    b.ToTable("EndUser");
                });
#pragma warning restore 612, 618
        }
    }
}
