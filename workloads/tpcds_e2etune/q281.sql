SELECT t.*, RANK() OVER (PARTITION BY t.s_state ORDER BY t.total_profit DESC) AS profit_rank_state
FROM (
    SELECT s.s_state,
           s.s_city,
           p.p_promo_name,
           cd.cd_gender,
           hd.hd_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_closed_date_sk IS NULL
      AND p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY s.s_state, s.s_city, p.p_promo_name, cd.cd_gender, hd.hd_income_band_sk
    HAVING SUM(ss.ss_net_profit) > 1000
) t
ORDER BY t.total_profit DESC
LIMIT 100
