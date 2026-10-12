WITH profit_by_warehouse_mode_brand AS (
  SELECT
    w.w_state AS warehouse_state,
    sm.sm_type AS ship_mode_type,
    i.i_brand AS product_brand,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(*) AS order_count
  FROM catalog_sales cs
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE
    sm.sm_type IN ('AIR', 'RAIL', 'SHIP')
    AND i.i_brand = 'BrandX'
    AND cs.cs_net_paid_inc_tax > 500
  GROUP BY
    w.w_state,
    sm.sm_type,
    i.i_brand
)
SELECT
  warehouse_state,
  ship_mode_type,
  product_brand,
  total_net_profit,
  avg_discount_amt,
  total_quantity,
  order_count,
  profit_rank
FROM (
  SELECT
    warehouse_state,
    ship_mode_type,
    product_brand,
    total_net_profit,
    avg_discount_amt,
    total_quantity,
    order_count,
    RANK() OVER (PARTITION BY warehouse_state ORDER BY total_net_profit DESC) AS profit_rank
  FROM profit_by_warehouse_mode_brand
) ranked
WHERE profit_rank <= 5
ORDER BY warehouse_state, profit_rank
