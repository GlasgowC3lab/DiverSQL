WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_ship_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_customer_sk,
    cs.cs_ship_hdemo_sk,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_catalog_page_sk,
    cs.cs_warehouse_sk,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_department,
    w.w_warehouse_id,
    w.w_state,
    w.w_warehouse_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    td.t_hour,
    td.t_am_pm,
    ARRAY[cs.cs_quantity, cs.cs_ext_discount_amt] AS qty_discount_arr
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
),
joined_returns AS (
  SELECT
    b.*,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_fee,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    wr.wr_fee
  FROM base b
  LEFT JOIN catalog_returns cr
    ON b.cs_order_number = cr.cr_order_number
   AND b.cs_item_sk = cr.cr_item_sk
  LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
  LEFT JOIN web_returns wr
    ON b.cs_order_number = wr.wr_order_number
  LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
),
expanded AS (
  SELECT
    j.*, 
    u.value AS qty_or_discount
  FROM joined_returns j
  CROSS JOIN UNNEST(j.qty_discount_arr) AS u (value)
),
agg AS (
  SELECT
    cp_catalog_number,
    cp_catalog_page_number,
    w_state,
    t_hour,
    ib_lower_bound,
    w_warehouse_id,
    qty_or_discount,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_sales_price) AS avg_sales_price,
    MIN(cs_net_profit) AS min_net_profit,
    MAX(cs_net_profit) AS max_net_profit,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amount,
    COUNT(*) AS row_cnt
  FROM expanded
  GROUP BY
    cp_catalog_number,
    cp_catalog_page_number,
    w_state,
    t_hour,
    ib_lower_bound,
    w_warehouse_id,
    qty_or_discount
)
SELECT
  cp_catalog_number,
  cp_catalog_page_number,
  w_state,
  t_hour,
  ib_lower_bound,
  orders_cnt,
  total_net_paid,
  avg_sales_price,
  min_net_profit,
  max_net_profit,
  total_return_amount,
  total_web_return_amount,
  qty_or_discount,
  ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_net_paid DESC) AS warehouse_sales_rank
FROM agg
WHERE cp_catalog_number = 17
  AND cp_catalog_page_number = 15
  AND t_hour BETWEEN 9 AND 17
  AND w_state = 'CA'
  AND ib_lower_bound >= 50000
ORDER BY total_net_paid DESC
LIMIT 100
