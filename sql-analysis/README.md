# SQL Analysis Layer

This folder adds a relational/SQL layer on top of the same NorthPeak FY2025
dataset used in the Excel workbook and Power BI dashboard — same 1,200 orders,
same business logic, queried directly with SQL instead of DAX.

## Files

| File | What it is |
|---|---|
| `sales_performance.db` | SQLite database — the same 3 tables (`sales_data`, `products`, `monthly_targets`), ready to query with any SQL client (DB Browser for SQLite, DBeaver, etc.) |
| `01_schema.sql` | DDL — `CREATE TABLE` statements, primary/foreign keys, indexes (portable ANSI SQL) |
| `02_analysis_queries.sql` | 16 queries answering every business question from the project brief, plus one bonus query |

## Schema

```
sales_data (fact table, 1,200 rows)
├── order_id (PK)
├── order_date
├── region, category, product, customer_segment, sales_channel, salesperson
├── units, unit_price, discount_pct
└── sales, cost, profit

products (dimension, 20 rows)
├── product (PK)
├── category
└── standard_price

monthly_targets (reference, 12 rows)
├── month_number (PK)
├── month
└── sales_target
```

## Sample results (verified against Excel & Power BI)

| Question | Result |
|---|---|
| Total Sales | $3,066,500.86 |
| Total Profit | $1,084,881.60 |
| Profit Margin | 35.38% |
| Total Orders | 1,200 |
| Total Units Sold | 9,952 |
| Average Order Value | $2,555.42 |
| Top region | West — $963,324 (34.53% margin) |
| Top category by revenue | Electronics — $2,029,439 (29.17% margin) |
| Highest-margin category | Software — 76.11% margin |
| Top product | Ultrabook Air 13 — $612,390 |
| Top customer segment | Enterprise — $1,768,060 (15.74% avg discount) |
| Top sales channel | Direct Sales — $1,501,358 (15.52% avg discount) |

## Techniques demonstrated

- **CTEs (`WITH` clauses)** — monthly aggregation before joining to targets
- **Window functions** — `RANK() OVER (...)` for top-product ranking, running
  cumulative sales with `SUM(...) OVER (ORDER BY ...)`
- **Joins** — `sales_data` ⋈ `products` to validate pricing logic
- **Conditional aggregation (`CASE WHEN`)** — bucketing discount % into bands
  to analyze the discount-vs-profit relationship
- **Multi-key grouping** — Category × Customer Segment profitability matrix

## How to run it

```bash
sqlite3 sales_performance.db < 01_schema.sql        # (only needed if rebuilding from scratch)
sqlite3 sales_performance.db < 02_analysis_queries.sql
```

Or open `sales_performance.db` directly in any SQLite-compatible tool (DB
Browser for SQLite, DBeaver, TablePlus, VS Code SQLite extension) and run the
queries interactively.
