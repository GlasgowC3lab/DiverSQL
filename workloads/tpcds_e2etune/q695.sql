WITH web_counts AS (
    SELECT d2.d_date_sk, COUNT(DISTINCT ws.web_site_sk) AS open_sites_cnt
    FROM web_site ws
    JOIN date_dim d2 ON ws.web_open_date_sk = d2.d_date_sk
    WHERE ws.web_country = 'United States'
    GROUP BY d2.d_date_sk
),
inventory_agg AS (
    SELECT inv_date_sk, inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_inv_qty
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
sales_agg AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq AS month,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        AVG(i.total_inv_qty) AS avg_inventory_on_hand,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        SUM(wc.open_sites_cnt) AS total_open_sites_in_month
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_agg i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN web_counts wc ON wc.d_date_sk = d.d_date_sk
    WHERE cs.cs_warehouse_sk IN (14, 2, 7)
      AND cs.cs_call_center_sk = 34
      AND d.d_year = 2020
      AND t.t_hour BETWEEN 8 AND 20
      AND w.w_state = 'CA'
    GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    w_warehouse_name,
    d_year,
    month,
    total_net_profit,
    total_sales,
    total_returns,
    total_net_profit - total_returns AS net_profit_after_returns,
    avg_inventory_on_hand,
    distinct_items_sold,
    total_open_sites_in_month,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (total_net_profit - total_returns) DESC) AS profit_rank
FROM sales_agg
ORDER BY net_profit_after_returns DESC
LIMIT 5
