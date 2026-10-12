WITH aggregated_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        p.p_promo_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, i.i_category, s.s_state, p.p_promo_name
)
SELECT d_year,
       i_category,
       s_state,
       p_promo_name,
       total_quantity,
       total_net_paid,
       total_net_profit
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS rn
    FROM aggregated_sales
) t
WHERE rn <= 10
ORDER BY d_year, total_net_profit DESC
LIMIT 100
