SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    ds.d_year AS ship_year,
    dsl.d_year AS sales_year,
    dstore.d_year AS store_closed_year,
    dwp.d_year AS wp_creation_year,
    dwp_access.d_year AS wp_access_year,
    c.c_customer_id AS refunded_customer_id,
    c.c_birth_year AS refunded_birth_year,
    c.c_preferred_cust_flag AS refunded_preferred_flag,
    rc.c_customer_id AS returning_customer_id,
    rc.c_birth_year AS returning_birth_year,
    s.s_store_id,
    s.s_market_id,
    s.s_state,
    wp.wp_url,
    wp.wp_type,
    SUM(cr.cr_return_amount) OVER (PARTITION BY c.c_customer_sk ORDER BY dr.d_date) AS cumulative_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY dr.d_date DESC) AS rn
FROM catalog_returns cr
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer rc ON cr.cr_returning_customer_sk = rc.c_customer_sk
JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk
JOIN date_dim dsl ON c.c_first_sales_date_sk = dsl.d_date_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim dstore ON s.s_closed_date_sk = dstore.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dr.d_date_sk AND wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim dwp ON wp.wp_creation_date_sk = dwp.d_date_sk
JOIN date_dim dwp_access ON wp.wp_access_date_sk = dwp_access.d_date_sk
WHERE dr.d_year BETWEEN 1999 AND 2002
  AND c.c_preferred_cust_flag = 'Y'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'HOME'
ORDER BY cumulative_return_amount DESC
LIMIT 100
