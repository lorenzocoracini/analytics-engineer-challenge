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

---

## Q1 — retest after schema.yml

**Iteration:** 2

**Generated Query:**
```sql
WITH monthly AS (
  SELECT
    date_trunc('month', delivery_date) AS month,
    COUNT(DISTINCT delivery_date::date) AS distinct_days
  FROM analytics.fact_loads
  WHERE delivery_date IS NOT NULL
  GROUP BY 1
),
full_months AS (
  SELECT m.month
  FROM monthly m
  JOIN monthly nxt
    ON nxt.month = m.month + INTERVAL '1 month'
  WHERE m.distinct_days >= 15
)
SELECT COUNT(*) AS loads_delivered_last_full_month
FROM analytics.fact_loads
WHERE date_trunc('month', delivery_date) = (SELECT MAX(month) FROM full_months);
```

**Answer:** 497

**Note:** the agent derived the "full month" logic itself from the schema.yml.

schema.yml change:
```yaml
      - name: delivery_date
        description: |
          Timestamp of actual delivery at destination.
          A month only counts as "full"/complete if BOTH: (1) it has at least
          15 distinct calendar days with a delivery, AND (2) the following
          calendar month also has at least one delivery (proof this month is
          over, not still accumulating).
        data_type: timestamp
```

---

## Q12 (bonus) — "What is the average delivery time?"

**Iteration:** 1

**Generated Query:**
```sql
SELECT AVG(delivery_date - pickup_date) AS average_load_time
FROM analytics.fact_loads
WHERE pickup_date IS NOT NULL AND delivery_date IS NOT NULL;
```

**Answer:** 1 day, 285 seconds

**Note:** First, the agent picked `pickup_date → delivery_date`, not the `book_date → delivery_date` definition assumed for this question. 


---

## Q12 (bonus) — retest after schema.yml fix

**Iteration:** 2

**Generated Query:**
```sql
SELECT AVG(delivery_date - book_date) AS average_delivery_time
FROM analytics.fact_loads
WHERE delivery_date IS NOT NULL
  AND book_date IS NOT NULL;
```

**Answer:** 6 days, 15116 seconds (~148.2 hours)

**Note:** the schema.yml note fixed the issue. the agent now consistently picks `delivery_date - book_date`, matching the documented assumption.

schema.yml change:
```yaml
      - name: book_date
        description: |
          Timestamp when the load was booked/confirmed by Loadsmart.
          "Delivery time" / load duration is defined as delivery_date - book_date.
          This is different from delivery_date - pickup_date, which
          measures only on-the-road transit time; don't use that for "delivery
          time" without saying so.
        data_type: timestamp
```

