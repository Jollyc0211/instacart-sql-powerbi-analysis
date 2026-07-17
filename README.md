# Instacart Shopping Behavior Analysis

SQL + Power BI project analyzing 5M+ rows of Instacart order data to explore basket size, order timing, product popularity, and customer loyalty.

**Full write-up:** see `case_study.docx` for the complete methodology, KPI results, and business insights.

## Highlights
- Cleaned and modeled a 5-table relational schema in PostgreSQL
- Built 5 core KPIs via reusable SQL views: basket size, order timing, top products, reorder rate, order cadence
- Found that reorder loyalty (milk variants, 87-91%) doesn't always match order volume (bananas lead by count)
- ~59% of all purchases are repeat buys — customers shop roughly every 17 days
- Built an interactive Power BI dashboard connected live to the database

## Tools
PostgreSQL · pgAdmin · Power BI Desktop

## Files
- `schema.sql` — table creation
- `cleaning_queries.sql` — data quality checks + cleaning views
- `kpi_queries.sql` — KPI queries
- `views.sql` — Power BI-facing views
- `dashboard.pbix` — Power BI file
- `case_study.docx` — full case study write-up
- `screenshots/` — dashboard preview images

## Dataset
[Instacart Market Basket Analysis](https://www.kaggle.com/competitions/instacart-market-basket-analysis) (Kaggle)
