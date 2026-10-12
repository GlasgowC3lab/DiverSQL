WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        c.c_salutation,
        c.c_customer_sk,
        p.p_promo_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sm.sm_ship_mode_id,
        sm.sm_code,
        i.inv_quantity_on_hand
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_salutation = 'Mrs.'
      AND ss.ss_sales_price > 50.00
      AND sm.sm_code = 'AIR'
      AND p.p_promo_name LIKE '%Clearance%'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    d_year,
    d_month_seq,
    c_salutation,
    sm_ship_mode_id,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss_ticket_number) AS order_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    MIN(ss_sales_price) AS min_price,
    MAX(ss_sales_price) AS max_price
FROM base
GROUP BY d_year, d_month_seq, c_salutation, sm_ship_mode_id
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
