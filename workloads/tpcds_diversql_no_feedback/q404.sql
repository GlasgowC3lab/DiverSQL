WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_brand,
        i.i_product_name,
        i.i_item_id,
        s.s_state,
        s.s_city,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        p.p_promo_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_product_name, '\\d{2}')
      AND i.i_item_id LIKE '00%'
      AND p.p_promo_name LIKE '%Clearance%'
      AND ss.ss_store_sk IN (
          SELECT s2.s_store_sk FROM store s2 WHERE s2.s_city LIKE '%Ville%'
      )
      AND ib.ib_lower_bound > 50000
)
SELECT
    s_state AS state,
    i_brand AS brand,
    COUNT(*) AS transaction_count,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_net_paid,
    REGEXP_EXTRACT(i_product_name, '([A-Za-z]+)\\s+[0-9]{2,}', 1) AS product_prefix
FROM filtered_sales
GROUP BY
    s_state,
    i_brand,
    REGEXP_EXTRACT(i_product_name, '([A-Za-z]+)\\s+[0-9]{2,}', 1)
ORDER BY total_net_paid DESC
LIMIT 100
