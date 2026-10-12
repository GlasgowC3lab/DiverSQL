WITH daily_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        d.d_year,
        s.s_state,
        i.i_category,
        i.i_brand,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 1
            ELSE 0
        END AS promo_active
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
),
agg_sales AS (
    SELECT
        d_year,
        s_state,
        i_category,
        i_brand,
        sum(ss_quantity) AS total_quantity,
        sum(ss_net_paid) AS total_net_paid,
        sum(ss_net_profit) AS total_net_profit,
        avg(ss_ext_discount_amt) AS avg_discount,
        sum(promo_active) AS promo_active_count
    FROM daily_sales
    GROUP BY d_year, s_state, i_category, i_brand
)
SELECT
    d_year,
    s_state,
    i_category,
    i_brand,
    total_quantity,
    total_net_paid,
    total_net_profit,
    avg_discount,
    promo_active_count,
    rank() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY d_year, profit_rank
LIMIT 200
