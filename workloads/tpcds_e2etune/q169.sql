WITH promo_sales AS (
    SELECT
        s.s_state,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
      AND s.s_state IS NOT NULL
    GROUP BY s.s_state, p.p_promo_name
)
SELECT
    ps.s_state,
    ps.p_promo_name,
    ps.total_net_profit,
    ps.total_sales,
    ps.avg_discount,
    ps.sales_cnt,
    RANK() OVER (PARTITION BY ps.s_state ORDER BY ps.total_net_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly' AND cp.cp_catalog_number BETWEEN 2 AND 4) AS monthly_catalog_pages,
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_type = 'landing') AS landing_page_count
FROM promo_sales ps
WHERE ps.total_net_profit > 5000
ORDER BY ps.s_state, profit_rank
LIMIT 200
