# Balanced-Tree-T-SQL-Analysis
A **comprehensive** T-SQL analytics project that transforms raw retail data into an **automated consolidated reporting suite** for executive level decision-making. This evaluates **15000+** transactions to identify top-performing products, analyze revenue splits, revenue distributions and uncover deep customer buying patterns.

## Introduction
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

## Tech Stack and Skills
  1. **Database:** Microsoft SQL Server (T-SQL)
  2. **Core Logic:** Common Table Expressions (CTEs), Window Functions (DENSE_RANK, SUM() OVER(), PERCENTILE_CONT), Aggregations, Complex Joins, DECLARE
  3. **Financial Formatting:** Advanced FORMAT() strings for Executive-ready currency and percentages.

## Project Structure
The analysis is broken into a modular structure:
  1. Database_Setup/: Contains the product_details schema and the sales transaction dataset (.csv)
  2. 00_Data_Cleaning.sql: Initial audit and formatting of raw data to ensure financial accuracy.
  3. 01_High_Level_Sales.sql: Key Performance Indicators like Total Quantities sold, Revenue and Total Discount
  4. 02_Transactional_Analysis.sql: Deep-dive into transactional analysis and revenue distribution.
  5. 03_Product_Analysis.sql: Category, Segment and Product level performance analysis and ranking.
  6. 04_Reporting_Challenge.sql: The "Executive Dashboard" combining all metrics into a single automated report.

## Key Insights and Highlights
  1. **Revenue Optimization:** Identified the top-performing "Category Toppers" and "Segment Toppers" driving the majority of growth.
  2. **Market Basket Analysis:** Successfully mapped "Product Triplets" to uncover hidden cross-selling opportunities within single transactions.
  3. **Member Loyalty ROI:** Quantified 20% transactions lift provided by registered members vs guests.
  4. **Executive Formatting:** All outputs in consolidated report are formatted to financial standards (e.g., $1,234.50 and 12.75%)

## How to Run
  1. Execute Database_Setup/product_details.sql to build table structure and insert values into product_details table
  2. Import Database_Setup/balanced_tree_sales.csv to create balanced_tree_sales table into database.
     
     **Crucial Configuraion:
     In the modify column section, manually modify below datatypes -
     qty, price, discount: Change to int
     start_txn_time: set to datetime
     member: Verify it is set to bit**
     
     ![SQL Import Wizard Mapping](Images/wizard_mapping.png)
     
  3. Run the analysis scripts in order (00 to 04) to clean data a bit and generate individual outputs and consolidated outputs.
