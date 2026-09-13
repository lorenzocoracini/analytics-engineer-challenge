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

**Fix applied:** added a note to `book_date`'s description in schema.yml recording the assumption: "delivery time" = `delivery_date - book_date`, distinct from `delivery_date - pickup_date` (transit time only).

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

