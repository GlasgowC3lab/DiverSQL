WITH agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_return_dates,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN (
        SELECT inv_date_sk, SUM(inv_quantity_on_hand) AS inv_quantity_on_hand
        FROM inventory
        GROUP BY inv_date_sk
    ) i
        ON i.inv_date_sk = d.d_date_sk
    WHERE cr.cr_reversed_charge > 0
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY sm.sm_type, d.d_year, d.d_month_seq
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    ship_mode_type,
    d_year,
    month_seq,
    total_return_loss,
    total_sales_profit,
    total_inventory_on_return_dates,
    distinct_return_orders,
    CASE WHEN total_sales_profit = 0 THEN NULL ELSE total_return_loss / total_sales_profit END AS loss_to_profit_ratio,
    RANK() OVER (PARTITION BY d_year ORDER BY CASE WHEN total_sales_profit = 0 THEN 0 ELSE total_return_loss / total_sales_profit END DESC) AS loss_profit_rank
FROM agg
ORDER BY d_year, loss_to_profit_ratio DESC
LIMIT 100
