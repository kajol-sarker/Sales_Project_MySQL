-- this is my first sql project.
create database sales;

use sales;

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;            

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Fact Sales Data.csv'
INTO TABLE fact_sales_data
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(OrderDate, StockDate, OrderNumber, ProductKey, CustomerKey, TerritoryKey, OrderLineItem, OrderQuantity);

-- safe mode on
set sql_safe_updates =0;

-- preprocess the calendar table for future usage
update calendar 
set date = str_to_date(date,'%m/%d/%Y');

-- moodify calendar table column date datatypes
alter table calendar
modify column date  Date;  


-- preprocess the customer table for future usage
update customer 
set BirthDate = str_to_date(BirthDate,'%m/%d/%Y');

-- modify customer table birthdate dtypes
alter table customer
modify column BirthDate Date;

-- change datatype for return_data table ReturnDate column
alter table returns_data
modify column ReturnDate Date;


-- Preprocess the Fact Table for future usage
update fact_sales_data 
set OrderDate = str_to_date(OrderDate,'%m/%d/%Y');

update  fact_sales_data
set StockDate = str_to_date(StockDate,'%m/%d/%Y');

-- modify fact table StockDate, OrderDate dtypes
alter table fact_sales_data
modify column OrderDate Date;

alter table fact_sales_data
modify column StockDate Date;


--  ----PROJECT REQUIREMENTS-----
-- 1. Retrieve all sales records. means show all from fact table 
select * from fact_sales_data;

-- 2. Get all distinct product names.
select distinct ProductName from product;

-- 3. Find all orders placed on a specific date.
select * from fact_sales_data
 where OrderDate = '2020-01-01';
 
-- 4. Retrieve all customers from a specific city. 
SELECT * FROM customer 
WHERE HomeOwner = 'Y';

-- 5. Find customers with a specific occupation.
SELECT * FROM customer 
WHERE Occupation = 'Skilled Manual';
 
-- 6. Count total number of products.
SELECT 
     COUNT(*) AS Total_Products
FROM product;

-- 7. Find the total number of orders.
SELECT
	 COUNT(DISTINCT OrderNumber) AS total_Orders
FROM fact_sales_data;

-- 8. Show products that cost more than $50.
SELECT * FROM product
FROM ProductCost > 50; 

-- 9. Find customers who earn more than $75,000 annually.
SELECT * FROM customer
WHERE AnnualIncome > 75000;

 
-- 10. Show customers born before 1980.
SELECT *
FROM customer
WHERE BirthDate < '1980-01-01';


-- 11. Find the oldest customer.
SELECT *
FROM customer
ORDER BY BirthDate ASC
LIMIT 1;


-- 12. Get the most recent sales order
SELECT *
FROM fact_sales_data
ORDER BY OrderDate DESC
LIMIT 1;


-- 13. Find the highest-priced product.
SELECT *
FROM product
ORDER BY ProductPrice DESC
LIMIT 1;


-- 14. Find the number of products in each category.
SELECT pc.CategoryName, COUNT(p.ProductKey) AS ProductCount
FROM product p
JOIN product_subcategories ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN product_categories pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY pc.CategoryName;


-- 15. Get all products with their categories.
SELECT p.ProductName, pc.CategoryName
FROM product p
JOIN product_subcategories ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN product_categories pc ON ps.ProductCategoryKey = pc.ProductCategoryKey;


-- 16. Show total sales revenue per region. 
SELECT t.Region, SUM(p.ProductPrice * fsd.OrderQuantity) AS TotalRevenue
FROM fact_sales_data fsd
JOIN product p ON fsd.ProductKey = p.ProductKey
JOIN territory t ON fsd.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Region;


-- 17. Find total sales quantity per product. 
SELECT p.ProductName, SUM(fsd.OrderQuantity) AS TotalQuantity
FROM fact_sales_data fsd
JOIN product p ON fsd.ProductKey = p.ProductKey
GROUP BY p.ProductName;


-- 18. Get total revenue per product category. 
SELECT pc.CategoryName, SUM(p.ProductPrice * fsd.OrderQuantity) AS TotalRevenue
FROM fact_sales_data fsd
JOIN product p ON fsd.ProductKey = p.ProductKey
JOIN product_subcategories ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN product_categories pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY pc.CategoryName;


-- 19. Find customers who have spent the most.
 SELECT c.Full_name, SUM(p.ProductPrice * fsd.OrderQuantity) AS TotalSpent
FROM fact_sales_data fsd
JOIN product p ON fsd.ProductKey = p.ProductKey
JOIN customer c ON fsd.CustomerKey = c.CustomerKey
GROUP BY c.Full_name
ORDER BY TotalSpent DESC;


-- 20. Get total orders by region.
SELECT t.Region, COUNT(DISTINCT fsd.OrderNumber) AS TotalOrders
FROM fact_sales_data fsd
JOIN territory t ON fsd.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Region;


-- 21. Find products that have been returned
SELECT DISTINCT p.ProductName
FROM returns_data r
JOIN product p ON r.ProductKey = p.ProductKey;


-- 22. Find sales trends over time
SELECT cal.Year, cal.Month_Name, SUM(fsd.OrderQuantity) AS TotalSales
FROM fact_sales_data fsd
JOIN calendar cal ON fsd.OrderDate = cal.date
GROUP BY cal.Year, cal.Month_Name
ORDER BY cal.Year, MIN(cal.date);


-- 23. Find the most popular product in each category
WITH product_sales AS (
    SELECT 
        pc.CategoryName,
        p.ProductName,
        SUM(fsd.OrderQuantity) AS TotalSold
    FROM fact_sales_data fsd
    JOIN product p 
        ON fsd.ProductKey = p.ProductKey
    JOIN product_subcategories ps 
        ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN product_categories pc 
        ON ps.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY pc.CategoryName, p.ProductName
),
ranked_sales AS (
    SELECT 
        CategoryName,
        ProductName,
        TotalSold,
        RANK() OVER (PARTITION BY CategoryName ORDER BY TotalSold DESC) AS rnk
    FROM product_sales
)
SELECT CategoryName, ProductName, TotalSold
FROM ranked_sales
WHERE rnk = 1;



-- 24. Find top 5 highest revenue-generating products
SELECT p.ProductName, SUM(p.ProductPrice * fsd.OrderQuantity) AS Revenue
FROM fact_sales_data fsd
JOIN product p ON fsd.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY Revenue DESC
LIMIT 5;


-- 25. Find Percentage of returned products
SELECT 
    (SUM(r.ReturnQuantity) / SUM(fsd.OrderQuantity) * 100) AS ReturnPercentage
FROM returns_data r
JOIN fact_sales_data fsd ON r.ProductKey = fsd.ProductKey;


-- 26. Find repeat customers
SELECT c.Full_name, COUNT(DISTINCT fsd.OrderNumber) AS OrderCount
FROM fact_sales_data fsd
JOIN customer c ON fsd.CustomerKey = c.CustomerKey
GROUP BY c.Full_name
HAVING COUNT(DISTINCT fsd.OrderNumber) > 1;


-- 27. Rank products by sales in each category
select 
     pc.CategoryName,
     p.ProductName,
     SUM(fc.OrderQuantity) AS Total_sold,
     RANK () OVER (PARTITION BY pc.CategoryName ORDER BY SUM(fc.OrderQuantity) DESC) AS Ranked_Category
FROM fact_sales_data AS fc
JOIN product AS p ON fc.Productkey = p.Productkey
JOIN product_subcategories AS ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN product_categories AS pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY  pc.CategoryName, p.ProductName ;


-- 28. Rank products by total revenue using RANK ( )
select 
     p.ProductName,
     SUM(fc.OrderQuantity * p.ProductPrice) AS Total_Revenue,
     RANK () OVER ( ORDER BY SUM(fc.OrderQuantity * p.ProductPrice) DESC) AS Rank_Revenue
FROM fact_sales_data AS fc
JOIN product AS p ON fc.ProductKey = p.ProductKey
GROUP BY  p.ProductName;

/*-- another way using CTE
WITH CTE AS (
SELECT
      p.ProductName,
      SUM(fc.OrderQuantity * p.ProductPrice) AS total_revenue
FROM fact_sales_data AS fc
JOIN product AS p ON fc.ProductKey = p.ProductKey 
GROUP BY p.ProductName
)
SELECT ProductName,
       round(total_revenue,2),
       RANK() OVER (ORDER BY total_revenue DESC) AS rank_revenue
FROM CTE;
*/


-- 29.  Find monthly total sales quantity. amr subidhar jonno CTE use kore korbo eta.
WITH  Monthly_Sales AS(
SELECT 
      c.Year,
      c.Month_Name,
     SUM(fc.OrderQuantity) AS Total_Quantity
FROM fact_sales_data AS fc
JOIN calendar as c on fc.OrderDate = c.date
GROUP BY c.Year, c.Month_Name
)
SELECT * FROM Monthly_Sales
ORDER BY year,Month_Name;


-- 30. Get top 3 products by sales in 2020. Boro boro calculation CTE use kore korbo.
WITH Product_Sales AS (
SELECT
     p.ProductName,
     SUM(fs.OrderQuantity) AS Total_Quantity
FROM fact_sales_data AS fs
JOIN product AS p ON fs.ProductKey = p.ProductKey
JOIN calendar AS c ON fs.OrderDate = c.date
where c.year = 2020
GROUP BY p.ProductName
) 
SELECT * FROM Product_Sales
ORDER BY total_quantity DESC
LIMIT 3;
