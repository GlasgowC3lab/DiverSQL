WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2453000
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_hdemo_sk, ss_promo_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    w.w_state,
    SUM(s.total_sales) AS sum_sales,
    AVG(s.total_profit) AS avg_profit,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    RANK() OVER (ORDER BY SUM(s.total_sales) DESC) AS sales_rank
FROM sales_agg s
JOIN customer c
    ON s.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON s.ss_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd
    ON s.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
WHERE d_sales.d_year = 2001
  AND ib.ib_lower_bound >= 50000
  AND hd.hd_buy_potential = '5001-10000'
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'TX'
  AND wp.wp_type = 'home'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential, w.w_state
ORDER BY sum_sales DESC
LIMIT 100
