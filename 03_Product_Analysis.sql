-- SET 3: PRODUCT ANALYSIS


 /* 
PROJECT: Balanced Tree Sales Analysis
MODULE 03: Product Analysis
PURPOSE: Analyze category, segment and product level performances by tracking KPIs like Net Revenue, Total Discounts, Best-Sellers, Revenue Contributions and Frequently Bought Together products.
IMPACT: Enables data-driven decisions on SKU discontinuation and targeted promotional startegies for underperforming segments, products. */


-- 1. What are the top 3 products by total revenue before discount?

SELECT TOP 3 WITH TIES 
	p.product_name, 
	SUM(s.qty*s.price) AS gross_revenue
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- Analysis: "Blue Polo Shirt - Men", "Grey Fashion Jacket - Women", "White Tee Shirt - Mens" are the top 3 drivers of revenue.



-- 2 What is the total quantity, revenue and discount for each segment?

SELECT p.segment_name, 
	SUM(s.qty) AS total_quantity, 
	SUM(s.qty*s.price) AS gross_revenue, 
	CAST(SUM(s.qty*s.price*(100-s.discount)/100.0) AS DECIMAL (10,2)) AS net_revenue, 
	CAST(SUM(s.qty*s.price*s.discount/100.0) AS DECIMAL (10,2)) AS total_discount
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name
ORDER BY 3 DESC;

-- Analysis: The Shirt segment is the primary driver of revenue (~ $356k) followed by Jacket and Socks. The fact that volume, revenue and discounts follow the same ranking suggests a consistent pricing strategy.



-- 3 What is the top selling product for each segment?

SELECT segment_name, product_name, CAST(net_revenue AS DECIMAL (10,2)) as net_revenue
FROM
(SELECT p.segment_name, p.product_name, SUM(s.qty*s.price*(100-s.discount)/100.0) AS net_revenue, DENSE_RANK() OVER(PARTITION BY p.segment_name ORDER BY SUM(s.qty*s.price*(100-s.discount)/100.0) DESC) AS best_selling_rank
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name, p.product_name) A
WHERE best_selling_rank =1
ORDER BY 3 DESC;

-- Analysis: 
-- Top Selling Product based on net revenue are Blue Polo Shirt (Shirt); Grey Fashion Jacket (Jacket); Navy Solid Socks (Socks); Black Straight Jeans (Jeans). 
-- This suggests that they drive the highest revenue (in their respective segments) even after providing discounts.



-- 4 What is the total quantity, revenue and discount for each category?
SELECT 
	  p.category_name
	, SUM(s.qty) as total_quantity
	, SUM(s.qty*s.price) AS gross_revenue
	, CAST(SUM(s.qty*s.price*(100-s.discount)/100.0) AS DECIMAL (10,2)) AS net_revenue
	, CAST(SUM(s.qty*s.price*s.discount/100.0) AS DECIMAL (10,2)) AS total_discount
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name;

-- Analysis: While the total products sold from each category are more or less equal, there is a significant difference in gross and net revenue. 
-- The Mens category generates higher revenue from similar volumes, indicating a higher average revenue per unit and stronger margins.
-- Conversely, the womens categroy generates lower revenue for similar volumes, indicating a lower average price per unit and lower margins.


-- 5 What is the top selling product for each category?
SELECT category_name, product_name, CAST(net_revenue AS DECIMAL (10,2)) AS net_category_revenue
FROM
(SELECT p.category_name, p.product_name, SUM(s.qty*s.price*(100-s.discount)/100.0) AS net_revenue, DENSE_RANK() OVER(PARTITION BY p.category_name ORDER BY SUM(s.qty*s.price*(100-s.discount)/100.0) DESC) AS best_selling_rank
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name, p.product_name) A
WHERE best_selling_rank = 1;

-- Analysis:
-- Mens: Top selling product by net revenue for Mens Category is Blue Polo Shirt and for womens category is Grey fashion Jacket
-- These products are "Face of the Category", contributing the highest individual net revenue to their respective categories and overall company.


-- 6 What is the percentage split of revenue by product for each segment?

SELECT 
	p.segment_name, 
	p.product_name,
	CAST(SUM(s.price*s.qty*(100-s.discount)/100.0) AS DECIMAL (10,2)) AS net_product_revenue,
	CAST(SUM(s.price*s.qty*(100-s.discount)/100.0)*100.0/SUM(SUM(s.price*s.qty*(100-s.discount)/100.0)) OVER(PARTITION BY p.segment_name) AS DECIMAL (10,2)) AS revenue_split_perc
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name, p.product_name
ORDER BY 1, 4 DESC;

--Analysis:
-- Every segment has atleast one product which is the revenue magnet with contribution of 40%-60% to total net revenue of the respective segemnt. 
-- Conversly, every segment has clear underperformers, like Teal Button Up Shirt in Shirt Segment (~ 9%), Cream Relaxed Jeans in Jeans Segment (~ 18%), Indigo Rain Jacket in Jacket Segment (~ 19%) and White Striped Socks in Socs Segment (~ 20%)



-- 7 What is the percentage split of revenue by segment for each category?

SELECT
	p.category_name, 
	p.segment_name, 
	CAST(SUM(s.price*s.qty*(100-s.discount)/100.0) AS DECIMAL (10,2)) AS net_segment_revenue,
	CAST(SUM(s.price*s.qty*(100-discount)/100.0)*100.0/SUM(SUM(s.price*s.qty*(100-discount)/100.0)) OVER(PARTITION by p.category_name) AS DECIMAL (5,2)) AS revenue_split_perc
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name, p.segment_name
ORDER BY 1,4 DESC;

-- Analysis: 
-- Mens Category: Shirt Segment is the primary driver of revenue, contributing 56.82% to net revenue
-- Womens Category: Jacket is the leader with 63.81% contribuiton to net revennue. The other segment's 'Jeans' contribution is significantly lower. This suggests an opportunity to narrow the gap, by focusing more on sales from Jeans Segment or adding a few new product-lines to this segment.



-- 8 What is the percentage split of total revenue by category?

SELECT 
	p.category_name, 
	CAST(SUM(s.price*s.qty*(100-discount)/100.0) AS DECIMAL (10,2)) AS category_revenue,
	CAST(SUM(s.price*s.qty*(100-discount)/100.0)*100.0/SUM(SUM(s.price*s.qty*(100-discount)/100.0)) OVER() AS DECIMAL (10,2)) AS revenue_split_perc
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name
ORDER BY 2 DESC;

-- Analysis: 
-- Mens Category is the primary driver of revenue, contributing 55.37% to total net revenue. 
-- While Womens category holds a strong 44.63% share, there is a clear opportunity to narrow this gap using promotional startegies.



-- 9 What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

DECLARE @txn_count INT
SET @txn_count = (SELECT COUNT(DISTINCT txn_id) FROM balanced_tree_sales);

SELECT p.product_name, 
		CAST(COUNT(DISTINCT txn_id)*100.0/@txn_count AS DECIMAL (5,2)) AS [transaction_penetration (%)]
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;

-- Analysis: Every product is appearing in nearly 50% of all transactions, indicating remarkably high product penetration across the catalog. Navy Solid Socks is the most frequent purchase as it has been bought in 51.24% of transactions.



-- 10 What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

SELECT TOP 1 WITH TIES
	p1.product_name AS Product_1, 
	p2.product_name AS Product_2, 
	p3.product_name AS Product_3, 
	COUNT(*) AS Frequency
FROM balanced_tree_sales s1
INNER JOIN balanced_tree_sales s2 ON s1.txn_id = s2.txn_id
INNER JOIN balanced_tree_sales s3 ON s2.txn_id = s3.txn_id
INNER JOIN product_details p1 ON s1.prod_id = p1.product_id
INNER JOIN product_details p2 ON s2.prod_id = p2.product_id
INNER JOIN product_details p3 ON s3.prod_id = p3.product_id
WHERE s1.prod_id < s2.prod_id AND s2.prod_id < s3.prod_id
GROUP BY p1.product_name, p2.product_name, p3.product_name
ORDER BY 4 DESC;

-- Analysis: The most frequent "bought together" triplet includes White Tee Shirt - Mens, Grey Fashion Jacket - Womens and Teal Button Up Shirt - Mens, which have been bought over 350 times. 