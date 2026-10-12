/*
Goal: Summarize net paid sales and refunded cash per customer and hour, filtered by birth month, time of day, quantity and cash thresholds, while demonstrating a scalar subquery comparison, an anti‑join (NOT IN), and a CROSS JOIN with a small constant set.
*/
WITH const_vals AS (
    SELECT 1 AS factor
    UNION ALL
    SELECT 2
),
base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_month,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        wr.wr_refunded_cash,
        wr.wr_return_quantity,
        wp.wp_type,
        t.t_hour,
        t.t_sub_shift
    FROM customer c
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_birth_month = 5
      AND t.t_sub_shift = 'morning'
      AND ss.ss_quantity > 2
      AND wr.wr_refunded_cash > 1000
      AND ss.ss_sales_price > (
            SELECT MAX(ss2.ss_sales_price)
            FROM store_sales ss2
            WHERE ss2.ss_quantity = 1
          )
      AND c.c_customer_sk NOT IN (
            SELECT wr2.wr_returning_customer_sk
            FROM web_returns wr2
            WHERE wr2.wr_return_amt > 5000
          )
)
SELECT
    b.c_customer_id,
    b.c_birth_month,
    b.ca_state,
    b.cd_gender,
    b.hd_income_band_sk,
    b.t_hour,
    SUM(b.ss_net_paid) AS total_net_paid,
    AVG(b.wr_refunded_cash) AS avg_refunded_cash,
    COUNT(DISTINCT b.ss_quantity) AS distinct_quantity_cnt,
    MIN(b.ss_sales_price) AS min_sales_price,
    MAX(b.ss_sales_price) AS max_sales_price,
    cv.factor
FROM base b
CROSS JOIN const_vals cv
GROUP BY
    b.c_customer_id,
    b.c_birth_month,
    b.ca_state,
    b.cd_gender,
    b.hd_income_band_sk,
    b.t_hour,
    cv.factor
ORDER BY total_net_paid DESC
LIMIT 100
