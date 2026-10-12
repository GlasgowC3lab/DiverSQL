/* Goal: Identify high‑value sales periods (hourly) where both catalog and store sales share common transaction identifiers, after applying multiple realistic filters, and compute aggregated sales and profit metrics. */
WITH joined AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_ext_list_price,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_ticket_number,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_net_profit,
        td.t_hour,
        td.t_am_pm,
        td.t_sub_shift
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'                                   -- filter 1
      AND td.t_sub_shift = 'evening'                           -- filter 2
      AND ss.ss_ext_list_price > 5000                          -- filter 3
      AND cs.cs_quantity > 50                                  -- filter 4
      AND cs.cs_net_profit > 0                                 -- filter 5
      AND ss.ss_quantity >= 10                                 -- filter 6
),
intersect_keys AS (
    SELECT ss_ticket_number AS key
    FROM joined
    WHERE ss_ext_list_price > 8000
    INTERSECT
    SELECT cs_order_number AS key
    FROM joined
    WHERE cs_quantity > 80
),
filtered AS (
    SELECT j.*
    FROM joined j
    JOIN intersect_keys ik
        ON j.ss_ticket_number = ik.key
)
SELECT
    f.t_hour,
    f.t_am_pm,
    COUNT(DISTINCT f.ss_ticket_number) AS distinct_ticket_cnt,
    SUM(f.ss_ext_sales_price) AS total_store_sales,
    AVG(f.cs_net_profit) AS avg_catalog_profit,
    MIN(f.ss_quantity) AS min_store_qty,
    MAX(f.cs_quantity) AS max_catalog_qty
FROM filtered f
GROUP BY f.t_hour, f.t_am_pm
ORDER BY total_store_sales DESC
LIMIT 100
