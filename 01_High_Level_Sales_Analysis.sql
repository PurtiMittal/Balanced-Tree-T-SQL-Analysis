--SET 1: HIGH LEVEL SALES ANALYSIS


/* 
PROJECT: Balanced Tree Sales Analysis
MODULE 01: High Level Sales Analysis
PURPOSE: Analyze overall sales performance using KPIs such as total quantities sold, gross revenue and total discounts.
IMPACT: Provides a high-level overview of sales performance to support strategic decision-making */



--Q1 What was the total quantity sold for all products?

SELECT SUM(qty) AS total_quantity_sold
FROM balanced_tree_sales;

-- Analysis: The total quantities sold accross all products is 45,216, indicating overall sales volume.



-- Q2 What is the total generated revenue for all products before discounts?

SELECT SUM(qty*price) AS gross_revenue
FROM balanced_tree_sales;

-- Analysis: Total revenue generated before discounts is approximately $1.29 Mn, indicating strong sales performance.



-- Q3 What was the total discount amount for all products?

SELECT CAST(SUM(qty*price*discount/100.0) AS DECIMAL (10,2)) AS total_discount_given 
FROM balanced_tree_sales

-- Analysis: Total discount provided to customers amount to approximately $156k on $1.29 Mn Sales (~12%), reflecting moderate discounting strategy.