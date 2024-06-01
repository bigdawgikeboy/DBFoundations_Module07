--*************************************************************************--
-- Title: Assignment07
-- Author: IsaacKareiva
-- Desc: This file demonstrates how to use Functions
-- 05/30/2024
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_IsaacKareiva')
	 Begin 
	  Alter Database [Assignment07DB_IsaacKareiva] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_IsaacKareiva;
	 End
	Create Database Assignment07DB_IsaacKareiva;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_IsaacKareiva;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
 3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.


-- first we create the function to convert into INT price into US dollar format
go -- make sure 'create' is first in batch
create function dbo.toDollars(@UnitPrice Float) -- important to have float to preserve decimals
	returns nvarchar(50)
	as
		begin
			return (
				select  '$' + convert(varchar(50), cast( @UnitPrice as money  ) ) -- use SQL money becuase this intuitively handles decimals
				-- then convert this to a varchar and add the dollar sign 
			) -- converts to dollars. see below note
		end
go

select productName, dbo.toDollars(UnitPrice) as 'US Dollars' from vProducts  -- use base view
order by productName
go


-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.


-- we use the same function but this time just make include a join
select CategoryName, ProductName, dbo.toDollars(UnitPrice) as 'US Dollars' from
	vCategories join vProducts on
		vProducts.CategoryID = vCategories.CategoryID 
order by CategoryName, ProductName
go

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- first we will construct the select/statement that gives us the appropriate data
select ProductName, InventoryDate, [Count]
from vInventories join vProducts on
	vInventories.ProductID = vProducts.ProductID
order by ProductName, InventoryDate

-- now we want to add in a function to display the date. 
-- we see that we can do most of this using built in sql functions 
select ProductName, DatePart(yy,InventoryDate), [Count]
from vInventories join vProducts on
	vInventories.ProductID = vProducts.ProductID
order by ProductName, InventoryDate

-- but a quick search of the sql documentation doesn't show a straightforward way
-- way to get the month name back (ex, January). so we use the 'choose' function to accomplish this
select ProductName
	,choose(month(InventoryDate), 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
	, DatePart(yy,InventoryDate), [Count]
from vInventories join vProducts on
	vInventories.ProductID = vProducts.ProductID
order by ProductName, InventoryDate

-- this works, now we just need to format it.  however, for readability purposes, it
-- would be nice to have this format parsing condensed into a single function.
-- so we will create a function first we can apply row by row

go
create function dbo.parseDate(@InventoryDate Date)
	returns nvarchar(50)
	as
		begin
			return (select choose(month(@InventoryDate), 
				'January', 'February', 'March', 
				'April', 'May', 'June', 'July', 
				'August', 'September', 'October',
				'November', 'December')  --formatting a little clunky but want to make sure what the function does is readable
				+ 
				', ' 
				+
				Cast(DatePart(yy,@InventoryDate)as nvarchar(50)) -- the DatePArt function returns what looks like an integer but
				-- is actually stored as a date type, so we have to cast it to a varchar
			)
		end
go

-- Finally we can write a cleaner select statement using this function
select ProductName
	, dbo.parseDate(InventoryDate) as 'Month and Year'
	, [Count]
from vInventories join vProducts on
	vInventories.ProductID = vProducts.ProductID
order by ProductName, InventoryDate
go

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- to accomplish the above we just need to make a view of our earlier select statement
go
create view vProductInventories as
	select top 10000000 -- necessary because we have an order by statement
		ProductName
		, dbo.parseDate(InventoryDate) as 'Month and Year'
		, [Count]
	from vInventories join vProducts on
		vInventories.ProductID = vProducts.ProductID
	order by ProductName, InventoryDate
go

select * from vProductInventories
go


-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- first construct the bare-bones table that gives us the results/data we need
select CategoryName, InventoryDate, [count], vProducts.ProductID
	from vInventories
		join vProducts
			on vInventories.ProductID = vProducts.ProductID
		join  vCategories
			on vProducts.CategoryID = vCategories.CategoryID


-- now add the earlier date parsing function
select CategoryName, dbo.parseDate(InventoryDate) as 'Month and YEar', [count]
	from vInventories
		join vProducts
			on vInventories.ProductID = vProducts.ProductID
		join  vCategories
			on vProducts.CategoryID = vCategories.CategoryID

--- now do 'TOTAL inventory count by category.  but be careful to use 'SUM', not count,
-- because we want to sum each of the counts for each category, not count how many counts we have.
select CategoryName, dbo.parseDate(InventoryDate)as 'MonthAndYear', sum([count]) as 'CategoryCount'
	from vInventories
		join vProducts
			on vInventories.ProductID = vProducts.ProductID
		join  vCategories
			on vProducts.CategoryID = vCategories.CategoryID
	group by CategoryName, InventoryDate


-- then  we add the order by clause
select CategoryName, dbo.parseDate(InventoryDate)as 'MonthAndYear', sum([count]) as 'CategoryCount'
	from vInventories
		join vProducts
			on vInventories.ProductID = vProducts.ProductID
		join  vCategories
			on vProducts.CategoryID = vCategories.CategoryID
	group by CategoryName, InventoryDate
order by CategoryName, InventoryDate  -- we order by 'inventory date' not or reformated string, because date not varchar orering

-- and finally we make a view of the whole thing
select CategoryName, dbo.parseDate(InventoryDate)as 'MonthAndYear', sum([count]) as 'CategoryCount'
	from vInventories
		join vProducts
			on vInventories.ProductID = vProducts.ProductID
		join  vCategories
			on vProducts.CategoryID = vCategories.CategoryID
group by CategoryName, InventoryDate
order by CategoryName, InventoryDate
go

-- and this is the final full statement
create view vCategoryByInventories  as
	select top 10000000
		CategoryName, dbo.parseDate(InventoryDate)as 'MonthAndYear', sum([count]) as 'CategoryCount'
			from vInventories
				join vProducts
					on vInventories.ProductID = vProducts.ProductID
				join  vCategories
					on vProducts.CategoryID = vCategories.CategoryID
	group by CategoryName, InventoryDate
	order by CategoryName, InventoryDate
go

Select * From vCategoryByInventories;
go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

--first we construct the bare bones SQL statement
select ProductName, [month and year], [count] 
	from
		vProductInventories
go

--now lets add the previous month count using the lag function
select 
	ProductName
	,[month and year]
	,[count] 
	, [PreviousMonthCount] = lag([count]) over(order by 
		ProductName, 
		PARSE([Month and Year] as datetime USING 'en-us')) --we want parse our string back as a date so we can preserve the ordering
from
	vProductInventories
go


--then we just need to make sure the nulls for January are set to 0.
select 
	ProductName
	,[month and year]
	,[count] 
	, [PreviousMonthCount] = 
		isnull(
				lag([count]) over(order by 
					ProductName, 
					PARSE([Month and Year] as datetime USING 'en-us'))
			, 0) --we  put a 0 if null
from
	vProductInventories
go

-- finally, we make all this a view
go
create view vProductInventoriesWithPreviousMonthCounts as
select top 1000000
	ProductName
	,[month and year]
	,[count] 
	, [PreviousMonthCount] = 
		isnull(
				lag([count]) over(order by 
					ProductName, 
					PARSE([Month and Year] as datetime USING 'en-us'))
			, 0) --we  put a 0 if null
from
	vProductInventories --we don't need an order by here because the view we used was already correctly ordered
go

Select * From vProductInventoriesWithPreviousMonthCounts
go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

--  this is the basic form of our command using the last question's view
Select ProductName, [month and year], [count], PreviousMonthCount
From vProductInventoriesWithPreviousMonthCounts

-- then we add the KPIs by combining 'where' clauses with 'case'
Select 
	ProductName
	, [month and year]
	, [count], PreviousMonthCount
	, [CountVsPreviousCountKPI] = case
		when [count] > PreviousMonthCount then 1 -- positive because the count grew from previous
		when [count] = PreviousMonthCount then 0
		when [count] < PreviousMonthCount then -1
	end
From vProductInventoriesWithPreviousMonthCounts

-- Finally we turn the whole thing into a view
go
create view vProductInventoriesWithPreviousMonthCountsWithKPIs as 
select top 100000 
	ProductName
	, [month and year]
	, [count], PreviousMonthCount
	, [CountVsPreviousCountKPI] = case
		when [count] > PreviousMonthCount then 1 -- positive because the count grew from previous
		when [count] = PreviousMonthCount then 0
		when [count] < PreviousMonthCount then -1
	end
From vProductInventoriesWithPreviousMonthCounts
go

-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.



-- since each function call returns a table, we want a Table Valued Function
Create Function fProductInventoriesWithPreviousMonthCountsWithKPIs(@KPI int)
 Returns @MyResults Table 
 -- below are the column names from the vProductInventoriesWithPreviousMonthCountsWithKPIs
 -- these get selected out in the later select statement, but we rrname them here in our @MyResults table
		( [ProductName] sql_variant 
		, [month and year] sql_variant
		, [count] sql_variant
		, [PreviousMonthCount] sql_variant
		, [CountVsPreviousCountKPI] sql_variant
		)
 As
  Begin --< Must use Begin and End with Complex table value functions
    Insert Into @MyResults
	-- and then we basically just write a simple select statement using are inputed KPI
	-- and insert this into our results value, with the aboce column listing lining up with our selection 
	 Select * from vProductInventoriesWithPreviousMonthCountsWithKPIs
		where CountVsPreviousCountKPI = @KPI
  Return
  End 
go


--Check that it works:
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
go

/***************************************************************************************/