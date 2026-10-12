WITH cs_with_array AS (
    SELECT
        cs.*, 
        ARRAY[CAST(cs.cs_quantity AS DOUBLE), CAST(cs.cs_ext_discount_amt AS DOUBLE)] AS metrics_arr
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt BETWEEN 500 AND 2000
      AND cs.cs_net_paid_inc_tax > 500
)
SELECT
    s.s_state,
    i.i_category,
    t.t_hour,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount,
    SUM(metric_value) AS sum_metrics,
    CASE WHEN AVG(cs.cs_ext_discount_amt) > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_level
FROM cs_with_array cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN item i
    ON i.i_item_sk = cr.cr_item_sk
JOIN customer c
    ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN time_dim t
    ON t.t_time_sk = cr.cr_returned_time_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN UNNEST(cs.metrics_arr) AS u(metric_value)
WHERE i.i_current_price BETWEEN 20 AND 100
  AND c.c_birth_day = 14
  AND w.w_warehouse_sq_ft > 500000
  AND t.t_hour BETWEEN 9 AND 17
  AND wp.wp_type = 'Product'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_quantity > 0
    )
GROUP BY s.s_state, i.i_category, t.t_hour
ORDER BY total_net_loss DESC, s.s_state ASC
LIMIT 100
