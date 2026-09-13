# Questions & Results

| # | Question | Generated SQL | Answer | Correct? | Iterations Needed | Notes |
|---|----------|----------------|--------|----------|--------------------|-------|
| Q1 | How many loads were delivered in the last full month available in the data? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q2 | Which shipper had the highest total book price? | `SELECT ds.shipper_name, SUM(fl.book_price) AS total_book_price FROM analytics.fact_loads fl JOIN analytics.dim_shipper ds ON fl.shipper_id = ds.shipper_id GROUP BY ds.shipper_name ORDER BY total_book_price DESC LIMIT 1;` | Shipper 1249 — $1,915,694.16 | Yes | 1 | |
| Q3 | What is the average book price per load by pickup state? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q4 | What are the top 5 lanes by number of delivered loads? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q5 | Which carrier moved the most loads into Texas? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q6 | How does the average book price compare between intrastate and interstate loads? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q7 | For the shipper with the most delivered loads, how did monthly volume change across the period covered by the data? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
| Q8 | Among lanes with at least 10 delivered loads, which had the highest average book price? | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ |
