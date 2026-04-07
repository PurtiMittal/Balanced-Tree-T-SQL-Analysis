-- SET 2: TRANSACTION ANALYSIS


/* 
PROJECT: Balanced Tree Sales Analysis
MODULE 02: Transaction Analysis
PURPOSE: Analyze overall transactions using KPIs including transaction volume, revenue distribution (percentiles) and average discount.
IMPACT: ProvideS insights about transactions to support a high level overview of transaction health and member vs non member behaviour */


-- Q1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS transaction_count
FROM balanced_tree_sales;

-- Analysis: Total transactions over the 3-month period is 2500, indicating good transactional volume.



-- Q2 What is the average unique products purchased in each transaction?

SELECT CAST(ROUND((COUNT(*)*1.0/COUNT(DISTINCT txn_id)),0) AS INT) AS average_unique_products_per_transaction -- Granuality of data is at txn_id & prod_id, count(*) accurately reflects total items ordered overall.
FROM balanced_tree_sales;

-- Analysis: Customers purchase an average of ~6 unqiue products per transaction. This suggests diverse product selection within each order.



-- Q3 What are the 25th, 50th and 75th percentile values for the revenue per transaction?

SELECT DISTINCT 
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_25, -- Using percentile_cont over grouped transaction totals to identify 'net revenue' distribution.
		PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_50,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_75
FROM balanced_tree_sales
GROUP BY txn_id;

-- Analysis: The median order value is $441.25. While Top 25% of orders exceed order value $572.76, the bulk of the transactions fall between $326.4 to $572.76.



-- Q4 What is the average discount value per transaction?
SELECT CAST(SUM(qty*price*discount/100.0)/COUNT(distinct txn_id) AS DECIMAL (10,2)) AS avg_discount
FROM balanced_tree_sales;

--Analysis: Average discount per order is $62.49. This suggests moderate discounting policy relative median order value of $441.25.



-- Q5 What is the percentage split of all transactions for members vs non-members?
SELECT 
	CAST(COUNT(DISTINCT CASE WHEN member = 1 THEN txn_id END)*100.0/COUNT(DISTINCT txn_id) AS DECIMAL(5,2)) AS member_perc_split,
	CAST(COUNT(DISTINCT CASE WHEN member = 0 THEN txn_id END)*100.0/COUNT(DISTINCT txn_id) AS DECIMAL (5,2)) AS non_member_perc_split
FROM balanced_tree_sales;

-- Analysis: 
-- Members account for 60.2% transactions out of all the transactions made during the 3-month period. This reflects the loyalty of our member customers. 
-- Non members contribute nearly 40%, indicating healthy reach to guest customers.



-- Q6 What is the average revenue for member transactions and non-member transactions?
SELECT 
	CAST(SUM(CASE WHEN member = 1 THEN (price*qty*(100-discount)/100.0) END)/COUNT(DISTINCT CASE WHEN member = 1 THEN txn_id END) AS DECIMAL (10,2)) AS member_avg_revenue,
	CAST(SUM(CASE WHEN member = 0 THEN (price*qty*(100-discount)/100.0) END)/COUNT(DISTINCT CASE WHEN member = 0 THEN txn_id END) AS DECIMAL (10,2)) AS non_member_avg_revenue
FROM balanced_tree_sales;

-- Analysis: Despite a gap of a 20% in transaction volume, both members and non-members drive similar average revenue per transaction (~ $450)
