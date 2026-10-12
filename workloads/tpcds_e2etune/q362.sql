WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT cs.cs_warehouse_sk,
           td.t_hour,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_quantity) AS total_quantity_sold,
           AVG(cs.cs_coupon_amt) AS avg_coupon_amt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_promo_sk = 1076
      AND cs.cs_call_center_sk = 1
      AND cs.cs_coupon_amt > 500
      AND td.t_hour BETWEEN 12 AND 23
    GROUP BY cs.cs_warehouse_sk, td.t_hour
)
SELECT w.w_warehouse_name,
       w.w_city,
       s.t_hour,
       s.total_net_profit,
       s.total_sales,
       s.total_quantity_sold,
       s.avg_coupon_amt,
       i.total_on_hand,
       s.total_net_profit / NULLIF(i.total_on_hand, 0) AS profit_per_onhand,
       RANK() OVER (PARTITION BY s.t_hour ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg i ON w.w_warehouse_sk = i.inv_warehouse_sk
ORDER BY s.total_net_profit DESC
LIMIT 10
