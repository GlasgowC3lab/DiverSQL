WITH
  -- Date dimension used multiple times under different aliases
  d_sales AS (
    SELECT * FROM date_dim
  ),
  d_inv AS (
    SELECT * FROM date_dim
  ),
  d_store_closed AS (
    SELECT * FROM date_dim
  ),
  d_web_creation AS (
    SELECT * FROM date_dim
  ),
  d_web_access AS (
    SELECT * FROM date_dim
  ),
  -- Distinct customers (uses DISTINCT keyword)
  distinct_customers AS (
    SELECT DISTINCT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
  ),
  -- Items that appear both in sales and inventory (INTERSECT)
  i_common AS (
    SELECT ss_item_sk AS item_sk
    FROM store_sales
    INTERSECT
    SELECT inv_item_sk
    FROM inventory
  ),
  -- Main aggregation query
  main AS (
    SELECT
      s.s_store_name,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
      d_sales.d_year,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
    FROM store_sales ss
      JOIN i_common ic ON ss.ss_item_sk = ic.item_sk
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN distinct_customers dc ON c.c_customer_sk = dc.c_customer_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
      JOIN inventory inv ON ss.ss_item_sk = inv.inv_item_sk
                             AND ss.ss_sold_date_sk = inv.inv_date_sk
      JOIN d_inv ON inv.inv_date_sk = d_inv.d_date_sk
      JOIN d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
      JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
      JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
      JOIN d_web_creation ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
      JOIN d_web_access ON wp.wp_access_date_sk = d_web_access.d_date_sk
      LEFT JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE NOT EXISTS (
          SELECT 1
          FROM inventory inv_check
          WHERE inv_check.inv_item_sk = ss.ss_item_sk
            AND inv_check.inv_date_sk = ss.ss_sold_date_sk
        )
    GROUP BY
      s.s_store_name,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
      d_sales.d_year
  )
SELECT *
FROM main
ORDER BY total_sales DESC
LIMIT 100
