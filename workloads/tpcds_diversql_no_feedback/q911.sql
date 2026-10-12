WITH joined_data AS (
  SELECT
    cr.cr_refunded_cash,
    cr.cr_refunded_customer_sk,
    ss.ss_item_sk,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    c.c_birth_country,
    c.c_salutation,
    t.t_hour,
    w.w_warehouse_name,
    w.w_state,
    w.w_gmt_offset,
    i.inv_quantity_on_hand
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE
    t.t_hour BETWEEN 8 AND 18
    AND c.c_birth_country = 'MEXICO'
    AND c.c_salutation = 'Mr.'
    AND cr.cr_refunded_cash > 200
    AND i.inv_quantity_on_hand < 500
    AND w.w_state = 'CA'
    AND w.w_gmt_offset > -5
),
agg AS (
  SELECT
    w_warehouse_name,
    t_hour,
    SUM(ss_net_profit) AS sum_net_profit,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cr_refunded_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT ss_item_sk) AS distinct_items_sold
  FROM joined_data
  GROUP BY w_warehouse_name, t_hour
)
SELECT
  w_warehouse_name,
  t_hour,
  CASE WHEN sum_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  total_sales,
  distinct_refunded_customers,
  distinct_items_sold,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS global_sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
