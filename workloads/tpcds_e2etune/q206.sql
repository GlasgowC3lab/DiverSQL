WITH sales_agg AS (
    SELECT i.i_category,
           sm.sm_ship_mode_id,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_quantity) AS total_quantity_sold,
           AVG(cs.cs_ext_discount_amt) AS avg_discount_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND t.t_shift = 'Evening'
    GROUP BY i.i_category, sm.sm_ship_mode_id
),
returns_agg AS (
    SELECT i.i_category,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_quantity) AS total_quantity_returned,
           AVG(sr.sr_return_amt) AS avg_return_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_shift = 'Evening'
    GROUP BY i.i_category
)
SELECT s.i_category,
       s.sm_ship_mode_id,
       s.total_net_profit,
       COALESCE(r.total_net_loss, 0) AS total_net_loss,
       s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_contribution,
       s.total_quantity_sold,
       COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
       s.avg_discount_amount,
       COALESCE(r.avg_return_amount, 0) AS avg_return_amount
FROM sales_agg s
LEFT JOIN returns_agg r ON s.i_category = r.i_category
ORDER BY net_contribution DESC
LIMIT 100
