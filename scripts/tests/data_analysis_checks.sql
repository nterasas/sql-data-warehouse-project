-- Change-Over-Time - Trends

-- Analyze how a measure evolves over time.
-- Help track trends and identify seasonality in your data.

-- Sum(Measure)	By [Date Dimension]
-- Total Sales	By Year
-- Average Cost	By Month

SELECT
YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)


SELECT
DATETRUNC(month, order_date) as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)


SELECT
FORMAT(order_date, 'yyyy-MMM') as order_date,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- Cumulative Analysis
-- Aggregate the data progressively over time.
-- Helps to understand whether our business is growing or declining.

-- Sum[Cumulative Measure]	By [Date Dimension]
-- Running Total Sales		By Year
-- Moving Average of Sales	By Month

-- Use Aggregate Windows functions to find cumulative values
-- Find Cumulative total sales by year / month

SELECT
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY DATETRUNC(year, order_date) ORDER BY order_date) AS running_total_sales
FROM
(
	SELECT
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales_amount) AS total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t


-- Use Aggregate Windows functions to find cumulative values
-- Find Moving Average

SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) AS moving_average
FROM
(
	SELECT
	DATETRUNC(year, order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(year, order_date)
)t



-- Performan Analysis
-- Comparing the current value to a target value.
-- Help measure success and compare performance.

-- Current[Measure] - Target[Measure]
-- Current Sales		-	Average Sales
-- Current Year Sales	-	Previous Yeare Sales <<--- YOY Analysis
-- Curren Sales			-	Lowest Sales


/* Analyze the yearly performance of products by comaring their sales
to both the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY
YEAR(f.order_date),
p.product_name
)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	 ELSE 'Avg'
END avg_change,
-- Year-over-year Analysis
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) py_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year


-- Part to Whole --->> Proportional Analysis
-- Analyze how an individual part is performing compared to the overall,
-- allowing us to understand which category has the greatest impact on the business.

-- ([Measure]/Total[Measure])	* 100	By [Dimension]
-- (Sales / Total Sales)		* 100	By Category
-- (Quantity / Total Quantity)	* 100	By Country

-- Which categories contribute the most to overall sales?
WITH category_sales AS (
	SELECT
	category,
	SUM(sales_amount) total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	GROUP BY category
)

SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST (total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales	
ORDER BY total_sales DESC



	
-- Data Segmentation
-- Group the data based on a specific range.
-- Helps understand the correlation between two measures.
-- [Measure]		By	[Measure]
-- Total Products	By	Sales Range
-- Total Customers	By	Age


/* Segment products into cost ranges and
count how many products fall into each segment */
WITH product_segment AS (
	SELECT
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 1000'
	END cost_range
	FROM gold.dim_products
)
SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC
