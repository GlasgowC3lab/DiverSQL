WITH filtered_sales AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_sales_price,
        p.p_promo_id,
        p.p_promo_name,
        sm.sm_type
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND i.i_container LIKE 'U%'
      AND cs.cs_ship_mode_sk IN (
          SELECT sm2.sm_ship_mode_sk
          FROM ship_mode sm2
          WHERE sm2.sm_contract LIKE '%A5BYO%'
      )
)
SELECT
    fs.p_promo_id,
    fs.p_promo_name,
    fs.sm_type,
    CONCAT(regexp_extract(fs.p_promo_id, '(\\d+)$'), '-', fs.sm_type) AS promo_code_type,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
FROM filtered_sales fs
GROUP BY
    fs.p_promo_id,
    fs.p_promo_name,
    fs.sm_type,
    CONCAT(regexp_extract(fs.p_promo_id, '(\\d+)$'), '-', fs.sm_type)
ORDER BY total_sales DESC
LIMIT 100
