CREATE DATABASE [AccountDB];
GO

USE [AccountDB];
GO
/*******************************************************************************
   Create Table
********************************************************************************/
CREATE TABLE [dbo].[Account]
(
    [CustomerId] INT NOT NULL PRIMARY KEY,
    [FirstName] NVARCHAR(40) NOT NULL,
    [LastName] NVARCHAR(20) NOT NULL,
    [Address] NVARCHAR(70),
    [City] NVARCHAR(40),
    [State] NVARCHAR(40),
    [Country] NVARCHAR(40),
    [PostalCode] NVARCHAR(10)
);
GO