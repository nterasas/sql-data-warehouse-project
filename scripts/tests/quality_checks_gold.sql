/*
========================================================================================
Quality Checks
========================================================================================
Script Purpose:
  This script performs quality checks to validate the integrity, consistency,
  and accuracy of the Gold layer.  These checks ensure:
  - Uniqueness of surrogate keys in dimension tables.
  - Referential integrity between fact and dimension tables.
  - Validation of relationships in teh data model for analytical purposes.

Usage Notes:
  - Run these checks after data loading Silver layer.
  -Investigate and resolve any discrepancies found during the checks.
========================================================================================
*/
-- ======================================================================================
-- Checking 'gold.dim_customers'
-- ======================================================================================
-- Check for uniqueness of Product Key in gold.dim_customers
-- Expectations:  No Result
SELECT
  customer_key,
  COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- ======================================================================================
-- Checking 'gold.dim_products'
-- ======================================================================================
-- Check for uniqueness of Product Key in gold.dim_products
-- Expectations:  No Result

  SELECT
    product_key,
    COUNT(*) AS duplicate_count
  FROM gold.dim_products
  GROUP BY product_key
  HAVING COUNT(*) > 1;




  
-- ======================================================================================
-- Checking 'gold.fact_sales'
-- ======================================================================================
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key 
WHERE p.product_key IS NULL OR c.customer_key IS NULL
