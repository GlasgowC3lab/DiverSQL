SELECT
    ib_lower_bound,
    ib_upper_bound,
    sales_buy_potential,
    num_customers,
    total_net_profit,
    avg_discount_amt,
    buy_potential_change_ratio,
    distinct_web_pages,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd_sales.hd_buy_potential AS sales_buy_potential,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(CASE WHEN hd_cust.hd_buy_potential <> hd_sales.hd_buy_potential THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS buy_potential_change_ratio,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM customer c
    JOIN store_sales ss
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_sales
      ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN household_demographics hd_cust
      ON c.c_current_hdemo_sk = hd_cust.hd_demo_sk
    JOIN income_band ib
      ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'IRELAND'
      AND c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_last_review_date > 2452400
      AND ss.ss_quantity > 5
      AND ss.ss_net_paid > 100
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd_sales.hd_buy_potential
) agg
ORDER BY profit_rank
LIMIT 10
