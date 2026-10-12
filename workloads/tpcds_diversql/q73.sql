WITH filtered_sales AS (
    SELECT
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_sales_price,
        cs.cs_net_paid,
        i.i_brand,
        i.i_category,
        i.i_units,
        i.i_rec_end_date,
        p.p_promo_name,
        p.p_promo_id,
        p.p_channel_catalog
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_promo_id = 'AAAAAAAADBAAAAAA'
      AND i.i_units = 'Box'
      AND i.i_rec_end_date = DATE '2000-10-26'
      AND cs.cs_ext_tax > 50
)
SELECT
    fs.i_brand,
    fs.i_category,
    fs.p_promo_name,
    COUNT(*) AS order_cnt,
    SUM(fs.cs_quantity) AS total_quantity,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_sales_price) AS avg_sales_price,
    MIN(fs.cs_ext_tax) AS min_tax,
    MAX(fs.cs_ext_tax) AS max_tax
FROM filtered_sales fs
GROUP BY fs.i_brand, fs.i_category, fs.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
