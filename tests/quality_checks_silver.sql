/*
================================================================================
Quality Checks
================================================================================
Script Purpose:
		This script performs various quality checks for consistency, accuracy,
		and standardization across the 'silver' schemas. It includes checks for:
			- Null or duplicate primary keys.
			- Unwanted spaces instring field.
			- Data standardization and consstency.
			- Invaid date ranges and orders.
			- Data consistency between related fields.

Usage Notes:
	- Run these checks after data loading Silver Layer
	- Investicate and resolve any discrepancies found during the checks.
=================================================================================
*/

--===========================================
-- Checking: silver.crm_cust_info
--===========================================
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


SELECT * FROM silver.crm_cust_info

--Check for unwanted Spaces
--Expectation: No Results
SELECT 
	cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

--Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info



--===========================================
-- Checking: silver.crm_prd_info
--===========================================
-- Check for Nulls or Duplicates in Primary key
-- Expectation: No Result
SELECT
COUNT(prd_id)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(prd_id) > 1 OR prd_id IS NULL

-- Check for unwanted spaces
-- Expectation: No Result
SELECT 
prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for Nulls or Negative Numbers
-- Expectation: No Result
SELECT
prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

--Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

--Check Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT *
FROM silver.crm_prd_info


--================================
--This is for finding the end date
--================================
SELECT 
prd_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS prd_end_dt_test
FROM silver.crm_prd_info
WHERE prd_key IN('AC-HE-HL-U509-R','AC-HE-HL-U509')




--===========================================
-- Checking: silver.crm_sales_details
--=========================================== 

--Check for Invalid Order Dates
SELECT 
NULLIF(sls_order_dt,0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0
OR LEN(sls_order_dt) != 8 
OR sls_order_dt >20500101 
OR sls_order_dt <19990101
--WHERE sls_order_dt >20500101 OR sls_order_dt <19990101 --checks the boundries


--Check for Invalid Shipping Dates
SELECT 
NULLIF(sls_ship_dt,0) AS sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt >20500101 
OR sls_ship_dt <19990101 --No problem here adding in case if it happens in future

--Check for Invalid Due Dates
SELECT 
NULLIF(sls_due_dt,0) AS sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8 
OR sls_due_dt >20500101 
OR sls_due_dt <19990101 

--Checks Invalid Date Orders
SELECT sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt >sls_order_dt OR sls_order_dt >sls_order_dt  

--Checks Data Consistency: Between Sales, Quantity and Price
-- >> Sales = Quantity * Price
-- >> Values must not be Null, Zero, or negative.
SELECT DISTINCT
	sls_sales AS old_sls_sales,
	sls_quantity,
	sls_price,
	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		 THEN sls_quantity * ABS(sls_price)
		 ELSE sls_sales
	END AS sls_sales,
	CASE WHEN sls_price IS NULL OR sls_price <=0 
		 THEN sls_sales / NULLIF(sls_quantity, 0)
		 ELSE sls_price
	END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

--Final check
SELECT * FROM silver.crm_sales_details




--===========================================
-- Checking: silver.erp_CUST_AZ12
--=========================================== 

--Identify out-of-Range Dates 
SELECT BDATE
FROM silver.erp_CUST_AZ12
WHERE BDATE < '1926-01-01'  OR BDATE > GETDATE()

--Data Standardization & Consistency 
SELECT DISTINCT
	GEN,
	CASE WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
		 ELSE 'n/a'
	END AS GEN
FROM silver.erp_CUST_AZ12

--Final look
SELECT * FROM silver.erp_CUST_AZ12


--===========================================
-- Checking: silver.erp_LOC_A101
--=========================================== 

--Data Standardization & Consistency
SELECT DISTINCT 
	CNTRY AS old_CNTRY,
	CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
	 ELSE TRIM(CNTRY)
END CNTRY
FROM silver.erp_LOC_A101
ORDER BY CNTRY

--Final look
SELECT * FROM silver.erp_LOC_A101



--===========================================
-- Checking: silver.erp_PX_CAT_G1V2
--=========================================== 

--Check for unwanted spaces
SELECT * FROM silver.erp_PX_CAT_G1V2
WHERE CAT != TRIM(CAT) OR SUBCAT != TRIM(SUBCAT) OR MAINTENANCE != TRIM(MAINTENANCE)

--Data Standardization & Consistency 
SELECT DISTINCT CAT
FROM silver.erp_PX_CAT_G1V2;

SELECT DISTINCT SUBCAT
FROM silver.erp_PX_CAT_G1V2;

SELECT DISTINCT MAINTENANCE
FROM silver.erp_PX_CAT_G1V2;

--Final look
SELECT * FROM silver.erp_PX_CAT_G1V2













