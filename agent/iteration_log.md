# Iteration Log

## Q1 — "How many loads were delivered in the last full month available in the data?"

**Iteration:** 1

**Generated Query:**
```sql
WITH max_date AS (
  SELECT MAX(delivery_date) AS max_delivery
  FROM analytics.fact_loads
),
last_full_month AS (
  SELECT DATE_TRUNC('month', max_delivery) - INTERVAL '1 month' AS month_start
  FROM max_date
)
SELECT COUNT(*) AS load_count
FROM analytics.fact_loads, last_full_month
WHERE delivery_date >= month_start
  AND delivery_date < month_start + INTERVAL '1 month';
```

**Answer:** 0

**Note:** treated February/2025 as the "last full month" (the month before `MAX(delivery_date)`), but February has no data at all. `MAX(delivery_date)` lands in March 2025 because of a single isolated row (2025-03-15). The actual last full month is December 2024 (497 loads).
