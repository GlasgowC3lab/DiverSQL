WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
      AND p.p_discount_active = 'Y'
    GROUP BY
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        hd.hd_income_band_sk
)
SELECT
    i_category,
    i_brand,
    p_promo_name,
    hd_income_band_sk,
    total_sales,
    total_discount,
    total_profit,
    txn_count,
    avg_quantity,
    total_sales / NULLIF(total_profit, 0) AS sales_to_profit_ratio,
    RANK() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank_in_category
FROM sales_agg
WHERE total_sales > 10000
ORDER BY i_category, sales_rank_in_category
