/* goal: Analyze total sales and profit for high‑channel promotions, broken down by income band and promotion name, using string filters and regex extraction, with grouping sets for multiple aggregation levels */
WITH filtered_sales AS (
    SELECT
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 500
      AND regexp_like(p.p_channel_details, '(?i)high')
      AND p.p_channel_catalog LIKE 'N%'
),
agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        COUNT(*) AS sales_cnt,
        SUM(ssf.ss_ext_sales_price) AS total_sales,
        SUM(ssf.ss_net_profit) AS total_profit
    FROM filtered_sales ssf
    JOIN household_demographics hd ON ssf.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ssf.ss_promo_sk = p.p_promo_sk
    GROUP BY GROUPING SETS (
        (ib.ib_lower_bound, ib.ib_upper_bound, p.p_promo_name),
        (ib.ib_lower_bound, ib.ib_upper_bound),
        (p.p_promo_name),
        ()
    )
)
SELECT
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.p_promo_name,
    agg.sales_cnt,
    agg.total_sales,
    agg.total_profit,
    CASE
        WHEN agg.ib_lower_bound IS NOT NULL AND agg.ib_upper_bound IS NOT NULL
        THEN concat('Income ', cast(agg.ib_lower_bound AS varchar), '-', cast(agg.ib_upper_bound AS varchar))
        ELSE NULL
    END AS income_range,
    CASE
        WHEN agg.p_promo_name IS NOT NULL
        THEN regexp_extract(agg.p_promo_name, '(\\w+)', 1)
        ELSE NULL
    END AS promo_first_word
FROM agg
ORDER BY total_sales DESC
LIMIT 100
