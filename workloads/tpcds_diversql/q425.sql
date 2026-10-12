WITH
base AS (
   SELECT
       ss.ss_sold_date_sk       AS sold_date_sk,
       ss.ss_sold_time_sk       AS sold_time_sk,
       ss.ss_item_sk            AS item_sk,
       ss.ss_customer_sk        AS cust_sk,
       ss.ss_addr_sk            AS addr_sk,
       ss.ss_promo_sk           AS promo_sk,
       ss.ss_ext_sales_price    AS sales_price,
       d.d_year,
       t.t_hour,
       i.i_current_price,
       c.c_birth_year,
       ca.ca_state,
       p.p_discount_active
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   WHERE i.i_current_price > 5
     AND d.d_year = 2000
     AND ca.ca_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND ss.ss_customer_sk IN (
           SELECT c_customer_sk FROM customer WHERE c_birth_year = 1955
         )
),
returns AS (
   SELECT
       wr.wr_item_sk          AS ret_item_sk,
       wr.wr_return_amt       AS return_amt,
       d.d_year               AS ret_year,
       t.t_hour               AS ret_hour,
       r.r_reason_desc,
       wp.wp_type,
       ca.ca_state            AS ret_state
   FROM web_returns wr
   JOIN date_dim d
     ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
     ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN item i
     ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_address ca
     ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2000
     AND i.i_current_price < 3
),
intersect_items AS (
   SELECT item_sk FROM base
   INTERSECT
   SELECT ret_item_sk FROM returns
),
sales_agg AS (
   SELECT
       d_year,
       SUM(sales_price) AS total_sales
   FROM base
   WHERE item_sk IN (SELECT item_sk FROM intersect_items)
   GROUP BY ROLLUP (d_year)
),
returns_agg AS (
   SELECT
       ret_year AS d_year,
       -SUM(return_amt) AS total_sales
   FROM returns
   GROUP BY ROLLUP (ret_year)
),
combined AS (
   SELECT 'sales'   AS src, d_year, total_sales FROM sales_agg
   UNION
   SELECT 'returns' AS src, d_year, total_sales FROM returns_agg
)
SELECT
    src,
    d_year,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY src) AS subtotal,
    (SELECT SUM(total_sales) FROM combined) AS grand_total,
    (SELECT AVG(i_current_price) FROM item) AS avg_item_price
FROM combined
WHERE d_year IS NOT NULL
  AND total_sales <> 0
ORDER BY src, d_year
LIMIT 100
