WITH intersect_orders AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
    INTERSECT
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_quantity > 0
)
SELECT
    cs.cs_order_number,
    d_sales.d_year,
    sm.sm_type,
    cust.c_customer_id,
    SUM(cs.cs_ext_sales_price)               AS total_sales,
    SUM(cr.cr_return_amount)                 AS total_returns,
    SUM(sr.sr_return_amt)                    AS total_store_returns,
    COUNT(DISTINCT cs.cs_item_sk)            AS distinct_items_sold
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer cust
  ON cs.cs_bill_customer_sk = cust.c_customer_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
 AND cs.cs_item_sk      = cr.cr_item_sk
LEFT JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_sales.d_date_sk
 AND sr.sr_return_time_sk   = t_sales.t_time_sk
 AND sr.sr_customer_sk      = cust.c_customer_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
WHERE cs.cs_order_number IN (SELECT * FROM intersect_orders)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 100
    )
GROUP BY
    cs.cs_order_number,
    d_sales.d_year,
    sm.sm_type,
    cust.c_customer_id
ORDER BY total_sales DESC
LIMIT 100
