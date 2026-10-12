WITH promo_period AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        start_d.d_date AS start_date,
        end_d.d_date AS end_date,
        p.p_cost,
        p.p_response_target
    FROM promotion p
    JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
    WHERE p.p_discount_active = 'Y'
),
sales_agg AS (
    SELECT
        ss.ss_promo_sk,
        d.d_year,
        d.d_current_quarter,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1903
      AND d.d_weekend = 'N'
    GROUP BY ss.ss_promo_sk, d.d_year, d.d_current_quarter
)
SELECT
    pp.p_promo_name,
    sa.d_current_quarter,
    sa.net_profit,
    sa.net_paid,
    sa.avg_discount,
    sa.sales_cnt,
    pp.p_cost,
    pp.p_response_target,
    RANK() OVER (PARTITION BY sa.d_current_quarter ORDER BY sa.net_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN promo_period pp ON sa.ss_promo_sk = pp.p_promo_sk
WHERE sa.net_profit > 10000
ORDER BY sa.d_current_quarter, profit_rank
