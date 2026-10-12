WITH sampled_sales AS (
   SELECT ws_sold_date_sk,
          ws_sold_time_sk,
          ws_item_sk,
          ws_order_number,
          ws_quantity,
          ws_net_paid_inc_ship_tax,
          ws_bill_addr_sk
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ws_net_paid_inc_ship_tax > 1000
     AND ws_quantity BETWEEN 1 AND 10
),
returns_filtered AS (
   SELECT wr_order_number,
          wr_item_sk,
          wr_return_amt,
          wr_account_credit,
          wr_return_quantity
   FROM web_returns
   WHERE wr_return_amt > 50
     AND wr_account_credit > 0
     AND wr_return_quantity >= 1
),
joined AS (
   SELECT s.ws_sold_time_sk,
          s.ws_item_sk,
          s.ws_order_number,
          s.ws_quantity,
          s.ws_net_paid_inc_ship_tax,
          r.wr_return_amt,
          r.wr_account_credit,
          t.t_shift,
          t.t_sub_shift,
          CASE WHEN r.wr_return_amt > 100 THEN 1 ELSE 0 END AS high_return_flag
   FROM sampled_sales s
   JOIN web_returns r
     ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
   JOIN time_dim t
     ON s.ws_sold_time_sk = t.t_time_sk
   WHERE t.t_shift IN ('first', 'second')
     AND t.t_sub_shift = 'afternoon'
),
agg1 AS (
   SELECT t_shift,
          t_sub_shift,
          ws_item_sk,
          SUM(ws_net_paid_inc_ship_tax) AS total_sales,
          SUM(COALESCE(wr_return_amt, 0)) AS total_returns,
          SUM(high_return_flag) AS high_return_count
   FROM joined
   GROUP BY GROUPING SETS (
       (t_shift, t_sub_shift),
       (ws_item_sk),
       ()
   )
),
order_numbers_all AS (
   SELECT ws_order_number
   FROM sampled_sales
),
order_numbers_returned AS (
   SELECT wr_order_number AS ws_order_number
   FROM returns_filtered
),
non_return_orders AS (
   SELECT ws_order_number
   FROM order_numbers_all
   EXCEPT
   SELECT ws_order_number
   FROM order_numbers_returned
)
SELECT a.t_shift,
       a.t_sub_shift,
       a.ws_item_sk,
       a.total_sales,
       a.total_returns,
       a.high_return_count,
       COUNT(DISTINCT n.ws_order_number) AS non_return_order_cnt,
       CASE WHEN a.total_sales = 0 THEN NULL
            ELSE a.total_returns / a.total_sales END AS return_rate
FROM agg1 a
LEFT JOIN non_return_orders n ON TRUE
GROUP BY a.t_shift,
         a.t_sub_shift,
         a.ws_item_sk,
         a.total_sales,
         a.total_returns,
         a.high_return_count
ORDER BY a.total_sales DESC
LIMIT 100
