WITH sales_cte AS (
  SELECT
    c.c_customer_id,
    d.d_year,
    'sale' AS activity_type,
    SUM(ss.ss_net_paid) AS amount,
    SUM(ss.ss_quantity) AS quantity
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND ss.ss_item_sk IN (
      SELECT inv.inv_item_sk
      FROM inventory inv
      WHERE inv.inv_quantity_on_hand > 800
    )
  GROUP BY c.c_customer_id, d.d_year
),
returns_cte AS (
  SELECT
    c.c_customer_id,
    d.d_year,
    'return' AS activity_type,
    SUM(wr.wr_return_amt) AS amount,
    SUM(wr.wr_return_quantity) AS quantity
  FROM web_returns wr
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND wr.wr_fee > 50
  GROUP BY c.c_customer_id, d.d_year
),
combined AS (
  SELECT * FROM sales_cte
  UNION ALL
  SELECT * FROM returns_cte
)
SELECT
  c.c_customer_id,
  c.d_year,
  c.activity_type,
  c.amount,
  c.quantity,
  SUM(c.amount) OVER (PARTITION BY c.c_customer_id ORDER BY c.activity_type
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount
FROM combined c
ORDER BY cumulative_amount DESC
LIMIT 100
