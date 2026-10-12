WITH refunded AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       c.c_customer_id,
       ca.ca_state,
       hd.hd_income_band_sk,
       row_number() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cr.cr_return_amount DESC) AS rnk
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE c.c_email_address LIKE '%@V.com'
     AND cr.cr_return_amount BETWEEN 10 AND 500
),
returning AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       c.c_customer_id,
       ca.ca_state,
       hd.hd_income_band_sk,
       row_number() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cr.cr_return_amount DESC) AS rnk
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   WHERE ca.ca_state = 'CA'
     AND cr.cr_return_amount > 0
),
top_refunded AS (
   SELECT * FROM refunded WHERE rnk <= 5
),
top_returning AS (
   SELECT * FROM returning WHERE rnk <= 5
),
combined AS (
   SELECT * FROM top_refunded
   UNION ALL
   SELECT * FROM top_returning
),
with_lateral AS (
   SELECT
       c.*, 
       t.total_order_return
   FROM combined c
   CROSS JOIN LATERAL (
       SELECT SUM(cr2.cr_return_amount) AS total_order_return
       FROM catalog_returns cr2
       WHERE cr2.cr_order_number = c.cr_order_number
   ) t
),
 groups AS (
   SELECT
       hd_income_band_sk,
       SUM(cr_return_amount) AS sum_return,
       COUNT(*) AS cnt
   FROM with_lateral
   GROUP BY hd_income_band_sk
   HAVING SUM(cr_return_amount) > 1000
)
SELECT
   w.cr_order_number,
   w.cr_return_amount,
   w.cr_return_quantity,
   w.c_customer_id,
   w.ca_state,
   w.hd_income_band_sk,
   w.total_order_return,
   g.sum_return,
   g.cnt
FROM with_lateral w
JOIN groups g ON w.hd_income_band_sk = g.hd_income_band_sk
WHERE w.cr_order_number NOT IN (
   SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 2000
)
ORDER BY w.hd_income_band_sk, w.cr_return_amount DESC
OFFSET 10 LIMIT 100
