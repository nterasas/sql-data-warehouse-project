INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line,
CAST (prd_start_dt AS DATE) AS prd_start_dt,
CAST (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info



-- Quality Checks
-- Check for Nulls or Duplicates in Primary Key
-- Expectation:  No Result

SELECT
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

SELECT sls_prd_key FROM silver.crm_sales_details


-- Check for unwanted Spaces
-- Expectation:  No Result

SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)


-- Check for NULLs or Negative Numbers
-- Expectation:  No Results

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL


-- Data Standardization & Consistency

SELECT DISTINCT prd_line
FROM silver.crm_prd_info



-- Check for Invalid Date Orders

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt_test
FROM silver.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

