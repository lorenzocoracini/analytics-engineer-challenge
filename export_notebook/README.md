# Export Notebook

Standalone notebook that exports the delivered loads from the last available month of the dataset to a CSV, using pandas instead of SQL.

## What it does

[`export_loads.ipynb`](export_loads.ipynb):

1. Connects to Postgres (`DATABASE_URL` from the repo-root `.env`) and reads the `analytics` mart tables (`fact_loads`, `dim_lane`, `dim_location`, `dim_shipper`, `dim_carrier`) into DataFrames.
2. Joins the star schema in pandas (fact + dimensions).
3. Filters to delivered loads (`delivery_date` not null and `load_was_cancelled` not true), then narrows down to the last available month (December 2024, the last month with complete data).
4. Exports the result to [`last_month_loads.csv`](last_month_loads.csv) with columns: `loadsmart_id`, `shipper_name`, `delivery_date`, `pickup_city`, `pickup_state`, `delivery_city`, `delivery_state`, `book_price`, `carrier_name`.

## Usage

Run all cells in `export_loads.ipynb`. Requires the `analytics` marts to already be built (`dbt run` in `elt/transformations`) and `DATABASE_URL` set (see [`.env.example`](../.env.example)).
