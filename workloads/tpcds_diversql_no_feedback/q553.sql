WITH filtered AS (
    SELECT
        i.inv_warehouse_sk,
        d.d_date,
        d.d_day_name,
        d.d_holiday,
        i.inv_quantity_on_hand,
        concat('WH', CAST(i.inv_warehouse_sk AS varchar), '-', substr(d.d_day_name, 1, 3)) AS warehouse_day_key,
        regexp_extract(d.d_holiday, '(\\w+)', 1) AS holiday_word
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'N'
      AND regexp_like(d.d_holiday, '^.*[Aa]dvent.*$')
      AND d.d_day_name LIKE 'S%'
),
aggregated AS (
    SELECT
        inv_warehouse_sk,
        d_date,
        warehouse_day_key,
        SUM(inv_quantity_on_hand) AS total_qty,
        MAX(holiday_word) AS holiday_word
    FROM filtered
    GROUP BY inv_warehouse_sk, d_date, warehouse_day_key
),
ranked AS (
    SELECT
        inv_warehouse_sk,
        d_date,
        warehouse_day_key,
        total_qty,
        holiday_word,
        row_number() OVER (PARTITION BY inv_warehouse_sk ORDER BY total_qty DESC) AS rn
    FROM aggregated
)
SELECT
    inv_warehouse_sk,
    d_date,
    warehouse_day_key,
    total_qty,
    holiday_word
FROM ranked
WHERE rn <= 5
ORDER BY inv_warehouse_sk, total_qty DESC
LIMIT 100
