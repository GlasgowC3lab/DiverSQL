WITH cc AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_country,
        d_cl.d_year AS cc_closed_year,
        d_op.d_year AS cc_open_year
    FROM call_center cc
    JOIN date_dim d_cl ON cc.cc_closed_date_sk = d_cl.d_date_sk
    JOIN date_dim d_op ON cc.cc_open_date_sk = d_op.d_date_sk
),
st AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year AS store_closed_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
),
cust AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d_ship.d_year AS ship_year,
        d_sales.d_year AS sales_year
    FROM customer c
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
),
wp AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        wp.wp_customer_sk,
        d_cre.d_year AS creation_year,
        d_acc.d_year AS access_year
    FROM web_page wp
    JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc ON wp.wp_access_date_sk = d_acc.d_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_closed_year,
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    st.store_closed_year,
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_type,
    wp.creation_year,
    wp.access_year,
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    cust.c_email_address,
    cust.ship_year,
    cust.sales_year,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY wp.creation_year DESC) AS rn
FROM cc
JOIN st   ON st.store_closed_year   = cc.cc_closed_year
JOIN wp   ON wp.creation_year      = cc.cc_closed_year
JOIN cust ON wp.wp_customer_sk     = cust.c_customer_sk
WHERE cc.cc_country = 'USA'
  AND st.s_state = 'CA'
  AND wp.wp_type = 'home'
  AND cust.c_email_address IS NOT NULL
ORDER BY cc.cc_closed_year DESC, rn
LIMIT 50
