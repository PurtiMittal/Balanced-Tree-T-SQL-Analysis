-- 04 Reporting Challenge: Executive Reporting Suite

/* This module consolidates the previous analysis into a set of production-ready reports designed for executive decision-making. By leveraging advanced t-SQL features like Window Functions (DENSE_RANK, PENCENTILE_CONT, OVER/PARTIITON BY)
and CTE- driven logics, this script generates a 360 degree view of business health - from high levEl transaction percentiles to identifying specific "frequently bought together" product-triplets to drive cross-selling strategies. */

-- Table 1 : High Level Sales & Transactions Summary (summarizes high-level sales & transactions analysis questions)

DECLARE @start_date DATE
DECLARE @end_date DATE
SET @start_date = '2021-01-01' -- Enter "start_date" of the reporting period
SET @end_date = '2021-04-01'; -- Enter "end_date + 1 day" of the reporting period.
-- Here we are checking for Jan 2021 to Mar 2021


WITH monthly_metrics AS
(SELECT
      SUM(qty) AS total_qty_sold
    , SUM(qty*price*1.0) AS total_gross_revenue
    , SUM(qty*price*discount/100.0) AS total_discount_given
    , COUNT(DISTINCT txn_id) AS transaction_count
    , COUNT(*)*1.0/COUNT(DISTINCT txn_id) AS avg_unique_products_per_transaction
    , SUM(qty*price*discount/100.0)/COUNT(DISTINCT txn_id) AS avg_discount_per_transaction
    , COUNT(DISTINCT CASE WHEN MEMBER = 1 THEN txn_id END)*1.0/COUNT(DISTINCT txn_id) AS member_txn_perc_split
    , COUNT(DISTINCT CASE WHEN MEMBER = 0 THEN txn_id END)*1.0/COUNT(DISTINCT txn_id) AS non_member_txn_perc_split
    , SUM(CASE WHEN MEMBER = 1 THEN (price*qty*(100-discount)/100.0) END)/COUNT(DISTINCT CASE WHEN MEMBER = 1 THEN txn_id END) AS member_avg_revenue
    , SUM(CASE WHEN MEMBER = 0 THEN (price*qty*(100-discount)/100.0) END)/COUNT(DISTINCT CASE WHEN MEMBER = 0 THEN txn_id END) AS non_member_avg_revenue
 FROM balanced_tree_sales
 WHERE start_txn_time >= @start_date AND start_txn_time < @end_date)

, percentile_calculations AS
 (SELECT DISTINCT
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_25
    , PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_50
    , PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY SUM(price*qty*(100-discount)/100.0)) OVER() AS percentile_75
 FROM balanced_tree_sales
 WHERE start_txn_time >= @start_date AND start_txn_time < @end_date
 GROUP BY txn_id)

SELECT 'Total Quantity Sold' AS Metrics , FORMAT(total_qty_sold, '#,###') AS [Amount] FROM monthly_metrics
UNION ALL
SELECT 'Total Gross Revenue' , FORMAT(total_gross_revenue, '$ #,##0.00')  FROM monthly_metrics
UNION ALL
SELECT 'Total Discount Given', FORMAT(total_discount_given, '$ #,##0.00') FROM monthly_metrics
UNION ALL
SELECT 'Total No. of Transactions', FORMAT(transaction_count, '#,###') FROM monthly_metrics
UNION ALL
SELECT 'Average Unique Products per Transaction', FORMAT(avg_unique_products_per_transaction, '#,###') FROM monthly_metrics
UNION ALL
SELECT 'Average Discount per Transaction', FORMAT(avg_discount_per_transaction, '$ #,##0.00') FROM monthly_metrics
UNION ALL
SELECT 'Transaction Percent Split (Member)', FORMAT(member_txn_perc_split, '#0.00%') FROM monthly_metrics
UNION ALL
SELECT 'Transaction Percent Split (Non Member)', FORMAT(non_member_txn_perc_split, '#0.00%') FROM monthly_metrics
UNION ALL
SELECT 'Average Revenue (Transactions by Member)', FORMAT(member_avg_revenue, '$ #,##0.00') FROM monthly_metrics
UNION ALL
SELECT 'Average Revenue (Transactions by Non-Member)', FORMAT(non_member_avg_revenue, '$ #,##0.00') FROM monthly_metrics
UNION ALL
SELECT '25th Percentile: Revenue per Transaction', FORMAT(percentile_25,'$ #,##0.00') FROM percentile_calculations 
UNION ALL
SELECT '50th Percentile: Revenue per Transaction',FORMAT(percentile_50,'$ #,##0.00') FROM percentile_calculations 
UNION ALL
SELECT '75th Percentile: Revenue per Transaction',FORMAT(percentile_75,'$ #,##0.00') FROM percentile_calculations;




-- Table 2: Multilevel Hierarcial Sales and Contribution Matrix (Covers que 2,4,7,8 of Product Analysis)

WITH category_segment_summary AS
(SELECT 
  p.category_name
, p.segment_name
, SUM(s.qty) AS segment_quantity
, SUM(s.qty*s.price*(100-s.discount)/100.0) AS segment_net_revenue
, SUM(s.qty*s.price*s.discount/100.0) AS segment_discount
, SUM(SUM(s.qty)) OVER(PARTITION BY p.category_name) AS category_quantity
, SUM(SUM(s.qty*s.price*(100-s.discount)/100.0)) OVER(PARTITION BY p.category_name) AS category_net_revenue
, SUM(SUM(s.qty*s.price*s.discount/100.0)) OVER(PARTITION BY p.category_name) AS category_discount
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
WHERE start_txn_time >= @start_date AND start_txn_time < @end_date
GROUP BY p.category_name, p.segment_name)

SELECT 
      category_name AS [Category Name]
    , segment_name AS [Segment Name]
    , FORMAT(segment_quantity, '#,###') AS [Segment Quantity]
    , FORMAT(segment_net_revenue, '$ #,##0.00') AS [Segment Net Revenue]
    , FORMAT(segment_discount,  '$ #,##0.00') AS [Segment Discount]
    , FORMAT(segment_net_revenue*1.0/category_net_revenue, '#0.00%') AS [Segment Revenue % Split]
    , FORMAT(category_quantity, '#,###') AS [Category Quantity]
    , FORMAT(category_net_revenue, '$ #,##0.00') AS [Category Net Revenue]
    , FORMAT(category_discount,  '$ #,##0.00') AS [Category Discount]
    , FORMAT(category_net_revenue*1.0/SUM(segment_net_revenue) OVER(), '#0.00%') AS [Category Revenue % Split]
FROM category_segment_summary
ORDER BY 1,2;





-- Table 3: Product Level Contribution and Key Metrics (Covers Que 1,3,5,6,9 of Product Analysis)

DECLARE @txn_count INT = (SELECT COUNT(DISTINCT txn_id) FROM balanced_tree_sales WHERE start_txn_time >= @start_date AND start_txn_time < @end_date);

WITH metrics AS
(SELECT 
      p.product_name
    , p.segment_name
    , p.category_name
    , SUM(s.price*s.qty) AS product_gross_revenue
    , SUM(s.price*s.qty*(100-s.discount)/100.0) AS product_net_revenue
    , COUNT(DISTINCT s.txn_id)*1.0/ @txn_count AS penetration
FROM balanced_tree_sales s
INNER JOIN product_details p ON s.prod_id = p.product_id
WHERE start_txn_time >= @start_date AND start_txn_time < @end_date
GROUP BY p.product_name, p.segment_name, p.category_name)

, rankings AS
(SELECT 
    product_name
  , segment_name
  , category_name
  , product_gross_revenue
  , product_net_revenue
  , penetration
  , product_net_revenue*1.0/SUM(product_net_revenue) OVER(PARTITION BY segment_name) AS perc_split
  , DENSE_RANK() OVER(ORDER BY product_gross_revenue desc) AS rn_overall
  , DENSE_RANK() OVER(PARTITION BY segment_name ORDER BY product_net_revenue DESC) AS rn_segment
  , DENSE_RANK() OVER(PARTITION BY category_name ORDER BY product_net_revenue DESC) AS rn_category
FROM metrics)


SELECT 
      product_name AS [Product Name]
    , segment_name AS [Segment Name]
    , category_name AS [Category Name]
    , FORMAT(product_net_revenue, '$ #,##0.00') AS [Product Net Revenue]
    , FORMAT(penetration, '#0.00%') AS [Transaction Penetration %]
    , FORMAT(perc_split, '#0.00%') AS [Revenue % Split (Segment)]
    , (CASE WHEN rn_overall =1 THEN 'Top 1st Overall  | ' ELSE '' END) + 
        (CASE WHEN rn_overall = 2 THEN 'Top 2nd Overall  | ' ELSE '' END) + 
        (CASE WHEN rn_overall = 3 THEN 'Top 3rd Overall  | ' ELSE '' END) + 
        (CASE WHEN rn_category = 1 THEN 'Category Topper | ' ELSE '' END) + 
        (CASE WHEN rn_segment = 1 THEN 'Segment Topper' ELSE '' END) 
      AS [Badge]
FROM rankings 
ORDER BY 3,2, product_net_revenue DESC




--- Table 4: Frequently Bought Together Triplet (Covers Que 10 of Product Analysis)

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
