-- =============================================================================
-- NorthPeak Distribution Co. — Sales Performance Analysis
-- Database Schema (DDL)
-- =============================================================================
-- Three tables, mirroring the Excel/Power BI data model:
--   sales_data       (fact table)   — 1,200 order-level transactions, FY2025
--   products         (dimension)    — 20 SKUs across 4 categories
--   monthly_targets  (reference)    — 12 rows, one per calendar month
--
-- Written in standard ANSI SQL (tested on SQLite; compatible with minor
-- syntax tweaks on PostgreSQL / MySQL / SQL Server).
-- =============================================================================

DROP TABLE IF EXISTS sales_data;
CREATE TABLE sales_data (
    order_id            VARCHAR(20)     PRIMARY KEY,
    order_date          DATE            NOT NULL,
    region              VARCHAR(20)     NOT NULL,
    category            VARCHAR(30)     NOT NULL,
    product             VARCHAR(50)     NOT NULL,
    customer_segment    VARCHAR(20)     NOT NULL,
    sales_channel       VARCHAR(20)     NOT NULL,
    salesperson         VARCHAR(50)     NOT NULL,
    units               INTEGER         NOT NULL,
    unit_price          DECIMAL(10,2)   NOT NULL,
    discount_pct        DECIMAL(6,4)    NOT NULL,
    sales               DECIMAL(12,2)   NOT NULL,   -- units * unit_price * (1 - discount_pct)
    cost                DECIMAL(12,2)   NOT NULL,   -- sales * category cost ratio
    profit              DECIMAL(12,2)   NOT NULL,   -- sales - cost
    FOREIGN KEY (product) REFERENCES products(product)
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product             VARCHAR(50)     PRIMARY KEY,
    category            VARCHAR(30)     NOT NULL,
    standard_price      DECIMAL(10,2)   NOT NULL
);

DROP TABLE IF EXISTS monthly_targets;
CREATE TABLE monthly_targets (
    month_number        INTEGER         PRIMARY KEY,   -- 1 = January ... 12 = December
    month                VARCHAR(20)     NOT NULL,
    sales_target         DECIMAL(12,2)   NOT NULL       -- planning figure, set manually
);

-- Helpful indexes for the query patterns used in 02_analysis_queries.sql
CREATE INDEX idx_sales_date       ON sales_data(order_date);
CREATE INDEX idx_sales_region     ON sales_data(region);
CREATE INDEX idx_sales_category   ON sales_data(category);
CREATE INDEX idx_sales_segment    ON sales_data(customer_segment);
CREATE INDEX idx_sales_channel    ON sales_data(sales_channel);
CREATE INDEX idx_sales_salesperson ON sales_data(salesperson);
