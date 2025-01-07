--1. Table Creation and Data Insertion
-- Create the Sales table with necessary columns
CREATE TABLE Sales (
    OrderID INT,                -- Order ID for each sale
    Product VARCHAR(255),       -- Product name
    Quantity INT,               -- Quantity of the product sold
    Price DECIMAL(10, 2),       -- Price of the product
    OrderDate DATE,             -- Date the order was placed
    TotalRevenue DECIMAL(10, 2),-- Total revenue from the sale
    City VARCHAR(100)           -- City where the product was sold
);

-- Insert data from the CSV file into the Sales table
BULK INSERT Sales
FROM 'C:\Users\marya\OneDrive - Høyskolen Kristiania\Revision Plan\SQL\Data Collection & Planning\Sales_Data_Cleaned_.csv'
WITH (
    FIELDTERMINATOR = ',',  -- Specifies that columns are separated by commas
    ROWTERMINATOR = '\n',   -- Specifies that rows are separated by newline characters
    FIRSTROW = 2           -- Skips the heade
);
--2. Basic Data Queries
-- Select the top 10 rows from the Sales table
SELECT TOP 10 * 
FROM Sales;

-- Count the total number of rows in the Sales table
SELECT COUNT(*) AS [Sales Count] 
FROM Sales;

-- Count the number of unique products in the Sales table
SELECT COUNT(DISTINCT Product) AS [Product Count]  
FROM Sales;

-- Select distinct products without repeating any
SELECT DISTINCT Product
FROM Sales;

-- Count the number of unique cities in the Sales table
SELECT COUNT(DISTINCT City) AS [City Count] 
FROM Sales;

-- Select distinct cities without repeating any
SELECT DISTINCT City
FROM Sales;

--3. Price Analysis
--(Focus on price data for products and cities)

-- Find the price of products in the Sales table in order from Max to Min
SELECT DISTINCT Product, Price AS [Product Price In Order]
FROM Sales
ORDER BY Price DESC;

-- CITY: Find the maximum price of products sold in each city and order the cities by highest sales
SELECT City, MAX(Price) AS [Cities Maximum Sales]
FROM Sales
GROUP BY City  -- Grouping by City so we can find the max sales per city
ORDER BY [Cities Maximum Sales] DESC;  -- Sorting by the highest price in descending order

-- Find the minimum price of products sold in each city and order the cities by lowest sales
SELECT City, MIN(Price) AS [Cities Minimum Sales]
FROM Sales
GROUP BY City  -- Grouping by City so we can find the min sales per city
ORDER BY [Cities Minimum Sales] ASC;  -- Sorting by the lowest price in ascending order

--4. Product and Order Analysis
--(Focus on most and least bought products, and order statistics)

-- PRODUCT: Find the most bought product (the product with the maximum sales quantity)
SELECT MAX(Product) AS [Most Bought Item] 
FROM Sales;

-- Find the least bought product (the product with the minimum sales quantity)
SELECT MIN(Product) AS [Least Bought Item] 
FROM Sales;

-- Get the OrderID that has ordered the most times
SELECT TOP 1 OrderID, COUNT(*) AS [Order Count]
FROM Sales
GROUP BY OrderID
ORDER BY [Order Count] DESC;

-- List the Names of the products for the OrderID with the highest distinct product count
WITH MostOrdered AS (
    SELECT OrderID, COUNT(DISTINCT Product) AS [Distinct Product Count]
    FROM Sales
    GROUP BY OrderID
)
SELECT S.OrderID, S.Product
FROM Sales S
JOIN MostOrdered M ON S.OrderID = M.OrderID
WHERE M.[Distinct Product Count] = (SELECT MAX([Distinct Product Count]) FROM MostOrdered)
ORDER BY S.OrderID, S.Product;

--5. Revenue and Yearly Analysis
--(Revenue-related analysis and breakdowns by year)

-- ANALYSIS OF TotalRevenue
-- Total Revenue: Sum of total revenue from all sales
SELECT SUM(TotalRevenue) as [Total Revenue SUM] FROM Sales;

-- Calculate Percentage of Sales for Top 5 Products with % 
WITH TotalRevenueSum AS (
    SELECT SUM(TotalRevenue) AS TotalRevenueSUM
    FROM Sales
)
SELECT TOP 5 
    Product, 
    SUM(TotalRevenue) AS Revenue,
    CONCAT(CAST(ROUND(SUM(TotalRevenue) * 100.0 / (SELECT TotalRevenueSUM FROM TotalRevenueSum), 2) AS DECIMAL(5, 2)), '%') AS PercentageOfTotalRevenue
FROM Sales
GROUP BY Product
ORDER BY Revenue DESC;

-- Total Years: Get distinct years from the OrderDate column
SELECT YEAR(OrderDate) AS Year
FROM Sales
GROUP BY YEAR(OrderDate);

-- Analysis of Revenue Over the Years with Percentage
WITH TotalRevenueSum AS (
    SELECT SUM(TotalRevenue) AS TotalRevenueSUM
    FROM Sales
)
SELECT  TOP 5
    YEAR(OrderDate) AS Year, 
    SUM(TotalRevenue) AS Revenue,
    CONCAT(CAST(ROUND(SUM(TotalRevenue) * 100.0 / (SELECT TotalRevenueSUM FROM TotalRevenueSum), 2) AS DECIMAL(5,2)), '%') AS PercentageOfTotalRevenue
FROM Sales
GROUP BY YEAR(OrderDate)
HAVING SUM(TotalRevenue) * 100.0 / (SELECT TotalRevenueSUM FROM TotalRevenueSum) > 0
ORDER BY Year;

-- Revenue Percentage Contribution by City
WITH CityRevenue AS (
    SELECT City, SUM(TotalRevenue) AS TotalRevenue
    FROM Sales
    GROUP BY City
),
TotalRevenue AS (
    SELECT SUM(TotalRevenue) AS TotalRevenueSum FROM Sales
)
SELECT 
    City, 
    TotalRevenue,
    CONCAT(CAST(ROUND((TotalRevenue * 100.0 / (SELECT TotalRevenueSum FROM TotalRevenue)), 2) AS DECIMAL (5,2)),'%') AS RevenuePercentage
FROM CityRevenue
ORDER BY TotalRevenue DESC;

-- Yearly Growth Rate: Yearly revenue growth percentage
WITH YearlyRevenue AS (
    SELECT YEAR(OrderDate) AS Year, SUM(TotalRevenue) AS Revenue
    FROM Sales
    GROUP BY YEAR(OrderDate)
)
SELECT 
    Year, 
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year) AS PreviousYearRevenue,
    ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Year)) * 100.0 / LAG(Revenue) OVER (ORDER BY Year), 2) AS GrowthRate
FROM YearlyRevenue;

--6. Product and Quarterly/Monthly Breakdown
--(Revenue and quantity breakdown by quarter, month, and product)


-- Best-Selling Products (by Quantity)
SELECT TOP 5 Product, SUM(Quantity) AS TotalQuantity
FROM Sales
GROUP BY Product
ORDER BY TotalQuantity DESC;

-- Quarterly Revenue
SELECT 
    YEAR(OrderDate) AS Year, 
    DATEPART(QUARTER, OrderDate) AS Quarter, 
    SUM(TotalRevenue) AS Revenue
FROM Sales
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY Year, Quarter;

-- Monthly Revenue
SELECT 
    YEAR(OrderDate) AS Year, 
    MONTH(OrderDate) AS Month, 
    SUM(TotalRevenue) AS TotalRevenue
FROM Sales
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY TotalRevenue DESC;

-- Total Revenue per Product
SELECT 
    Product, 
    SUM(Quantity) AS TotalQuantity, 
    SUM(TotalRevenue) AS TotalRevenue
FROM Sales
GROUP BY Product
ORDER BY TotalRevenue DESC; 

-- Total Revenue for Macbook Pro Laptop by City
SELECT 
    City, 
    Product, 
    SUM(TotalRevenue) AS Revenue
FROM Sales
WHERE Product = 'Macbook Pro Laptop'
GROUP BY City, Product
ORDER BY Revenue DESC;

-- Step 1: Create the MonthlyRevenue table
CREATE TABLE MonthlyRevenue (
    Month INT,              -- Month of the order
    Year INT,               -- Year of the order
    Revenue DECIMAL(18, 2)  -- Total revenue for the month
);

-- Step 2: Populate the MonthlyRevenue table with aggregated data
INSERT INTO MonthlyRevenue (Month, Year, Revenue)
SELECT 
    MONTH(OrderDate) AS Month,  -- Extract the month
    YEAR(OrderDate) AS Year,    -- Extract the year
    SUM(TotalRevenue) AS Revenue -- Calculate total revenue for each month and year
FROM Sales
GROUP BY 
    YEAR(OrderDate), 
    MONTH(OrderDate); -- Group by year and month to aggregate data

-- View the data in the MonthlyRevenue table
SELECT * FROM MonthlyRevenue;



--7. Cleanup
--(Drop the table after the analysis if necessary)
--Drop the Sales table after the analysis is done (optional, be careful with this step)
DROP TABLE Sales,MonthlyRevenue ;
