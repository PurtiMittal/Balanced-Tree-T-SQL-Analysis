
/* 
PROJECT: Balanced Tree Sales Analysis
MODULE 00: Data Cleaning
PURPOSE: Clean the data by removing the leading single quote (') from txn_id column, introduced during data import into Excel
IMPACT: Ensures data consistency and maintains data integrity for accurate analysis
*/

UPDATE balanced_tree_sales
SET txn_id = RIGHT(txn_id, LEN(txn_id)-1) --
WHERE LEFT(txn_id,1) = '''' -- only updates the rows with the single quote prefix