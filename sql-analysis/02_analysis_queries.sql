-- =============================================================================
-- NorthPeak Distribution Co. — Sales Performance Analysis
-- Analysis Queries — answers the 16 business questions from the project brief
-- =============================================================================
-- Tested against SQLite (sales_performance.db). Date functions (strftime) are
-- SQLite-specific; swap for EXTRACT(MONTH FROM order_date) on PostgreSQL or
-- MONTH(order_date) on MySQL/SQL Server if porting.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. TOTAL SALES
-- -----------------------------------------------------------------------------
SELECT ROUND(SUM(sales), 2) AS total_sales
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 2. TOTAL PROFIT
-- -----------------------------------------------------------------------------
SELECT ROUND(SUM(profit), 2) AS total_profit
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 3. PROFIT MARGIN (%)
-- -----------------------------------------------------------------------------
SELECT ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 4. TOTAL ORDERS
-- -----------------------------------------------------------------------------
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 5. TOTAL UNITS SOLD
-- -----------------------------------------------------------------------------
SELECT SUM(units) AS total_units_sold
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 6. AVERAGE ORDER VALUE (AOV)
-- -----------------------------------------------------------------------------
SELECT ROUND(SUM(sales) * 1.0 / COUNT(DISTINCT order_id), 2) AS average_order_value
FROM sales_data;


-- -----------------------------------------------------------------------------
-- 7. SALES VS TARGET (by month)
-- -----------------------------------------------------------------------------
WITH monthly_actual AS (
    SELECT
        CAST(strftime('%m', order_date) AS INTEGER) AS month_number,
        SUM(sales) AS actual_sales
    FROM sales_data
    GROUP BY month_number
)
SELECT
    mt.month_number,
    mt.month,
    mt.sales_target,
    ROUND(ma.actual_sales, 2)                                    AS actual_sales,
    ROUND(ma.actual_sales - mt.sales_target, 2)                  AS variance_abs,
    ROUND((ma.actual_sales - mt.sales_target) / mt.sales_target * 100, 1) AS variance_pct
FROM monthly_targets mt
JOIN monthly_actual ma ON mt.month_number = ma.month_number
ORDER BY mt.month_number;


-- -----------------------------------------------------------------------------
-- 8. MONTHLY SALES TREND (with running/cumulative total)
-- -----------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT
        CAST(strftime('%m', order_date) AS INTEGER) AS month_number,
        strftime('%Y-%m', order_date)                AS year_month,
        SUM(sales) AS monthly_sales
    FROM sales_data
    GROUP BY month_number, year_month
)
SELECT
    month_number,
    year_month,
    ROUND(monthly_sales, 2) AS monthly_sales,
    ROUND(SUM(monthly_sales) OVER (ORDER BY month_number), 2) AS cumulative_sales
FROM monthly_sales
ORDER BY month_number;


-- -----------------------------------------------------------------------------
-- 9. REGIONAL PERFORMANCE
-- -----------------------------------------------------------------------------
SELECT
    region,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(SUM(sales), 2)                   AS total_sales,
    ROUND(SUM(profit), 2)                  AS total_profit,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data
GROUP BY region
ORDER BY total_sales DESC;


-- -----------------------------------------------------------------------------
-- 10. CATEGORY PERFORMANCE
-- -----------------------------------------------------------------------------
SELECT
    category,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(SUM(sales), 2)                   AS total_sales,
    ROUND(SUM(profit), 2)                  AS total_profit,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data
GROUP BY category
ORDER BY total_sales DESC;


-- -----------------------------------------------------------------------------
-- 11. TOP PRODUCTS (Top 10 by Sales, with rank)
-- -----------------------------------------------------------------------------
SELECT
    product,
    category,
    ROUND(SUM(sales), 2)  AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
FROM sales_data
GROUP BY product, category
ORDER BY total_sales DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 12. CUSTOMER SEGMENT PERFORMANCE
-- -----------------------------------------------------------------------------
SELECT
    customer_segment,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(SUM(sales), 2)                   AS total_sales,
    ROUND(SUM(profit), 2)                  AS total_profit,
    ROUND(AVG(discount_pct), 4)            AS avg_discount_pct,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data
GROUP BY customer_segment
ORDER BY total_sales DESC;


-- -----------------------------------------------------------------------------
-- 13. SALES CHANNEL PERFORMANCE
-- -----------------------------------------------------------------------------
SELECT
    sales_channel,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(SUM(sales), 2)                   AS total_sales,
    ROUND(SUM(profit), 2)                  AS total_profit,
    ROUND(AVG(discount_pct), 4)            AS avg_discount_pct,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data
GROUP BY sales_channel
ORDER BY total_sales DESC;


-- -----------------------------------------------------------------------------
-- 14. SALESPERSON PERFORMANCE (Top 10)
-- -----------------------------------------------------------------------------
SELECT
    salesperson,
    region,
    COUNT(DISTINCT order_id)  AS total_orders,
    ROUND(SUM(sales), 2)      AS total_sales,
    ROUND(SUM(profit), 2)     AS total_profit
FROM sales_data
GROUP BY salesperson, region
ORDER BY total_sales DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 15. DISCOUNT VS PROFIT (bucketed analysis)
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN discount_pct < 0.05 THEN '0-5%'
        WHEN discount_pct < 0.10 THEN '5-10%'
        WHEN discount_pct < 0.15 THEN '10-15%'
        WHEN discount_pct < 0.20 THEN '15-20%'
        ELSE '20%+'
    END AS discount_band,
    COUNT(*)                                AS order_count,
    ROUND(AVG(discount_pct), 4)             AS avg_discount_pct,
    ROUND(SUM(sales), 2)                    AS total_sales,
    ROUND(SUM(profit), 2)                   AS total_profit,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS avg_profit_margin
FROM sales_data
GROUP BY discount_band
ORDER BY avg_discount_pct;


-- -----------------------------------------------------------------------------
-- 16. PROFITABILITY ANALYSIS (Category x Customer Segment matrix)
-- -----------------------------------------------------------------------------
SELECT
    category,
    customer_segment,
    ROUND(SUM(sales), 2)                    AS total_sales,
    ROUND(SUM(profit), 2)                   AS total_profit,
    ROUND(SUM(profit) * 1.0 / SUM(sales), 4) AS profit_margin_pct
FROM sales_data
GROUP BY category, customer_segment
ORDER BY category, total_sales DESC;


-- -----------------------------------------------------------------------------
-- BONUS: Products table join — how far each order's unit price deviated from
-- the product's Standard Price (validates the pricing logic behind the data)
-- -----------------------------------------------------------------------------
SELECT
    sd.sales_channel,
    ROUND(AVG(sd.unit_price / p.standard_price - 1) * 100, 2) AS avg_price_variance_pct
FROM sales_data sd
JOIN products p ON sd.product = p.product
GROUP BY sd.sales_channel
ORDER BY avg_price_variance_pct DESC;
