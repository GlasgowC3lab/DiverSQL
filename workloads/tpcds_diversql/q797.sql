WITH intersected_customers AS (
   SELECT cust_sk FROM (
       SELECT DISTINCT wr.wr_returning_customer_sk AS cust_sk
       FROM web_returns wr
       JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
   )
   INTERSECT
   SELECT cust_sk FROM (
       SELECT DISTINCT wp.wp_customer_sk AS cust_sk
       FROM web_page wp
       JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
   )
),
excluded_customers AS (
   SELECT c.c_customer_sk AS cust_sk
   FROM customer c
   JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
   WHERE d.d_year = 1999
),
final_customers AS (
   SELECT cust_sk FROM intersected_customers
   EXCEPT
   SELECT cust_sk FROM excluded_customers
),
base AS (
   SELECT
       fc.cust_sk,
       wr.wr_return_amt,
       wr.wr_return_quantity,
       d_ret.d_year AS return_year,
       inv.inv_item_sk,
       inv.inv_quantity_on_hand,
       wp.wp_type,
       wp_cust.c_customer_sk AS wp_customer_key,
       cust_refunded.c_customer_sk AS refunded_customer_key,
       d_cust_sales.d_year AS sales_year
   FROM final_customers fc
   JOIN web_returns wr
     ON fc.cust_sk = wr.wr_returning_customer_sk
   JOIN date_dim d_ret
     ON wr.wr_returned_date_sk = d_ret.d_date_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d_wp_creation
     ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   JOIN date_dim d_wp_access
     ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   JOIN customer wp_cust
     ON wp.wp_customer_sk = wp_cust.c_customer_sk
   JOIN inventory inv
     ON inv.inv_date_sk = d_ret.d_date_sk
   JOIN date_dim d_inv
     ON inv.inv_date_sk = d_inv.d_date_sk
   JOIN customer cust_refunded
     ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
   JOIN date_dim d_cust_sales
     ON cust_refunded.c_first_sales_date_sk = d_cust_sales.d_date_sk
)
SELECT
   base.cust_sk AS customer_key,
   base.return_year,
   CASE WHEN base.wr_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_amount_category,
   COUNT(*) AS num_returns,
   SUM(base.wr_return_amt) AS total_return_amt,
   AVG(base.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM base
WHERE NOT EXISTS (
   SELECT 1
   FROM inventory inv2
   WHERE inv2.inv_item_sk = base.inv_item_sk
     AND inv2.inv_quantity_on_hand < 0
)
GROUP BY
   base.cust_sk,
   base.return_year,
   CASE WHEN base.wr_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_return_amt DESC
LIMIT 100
