WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        d.d_year,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        concat(i.i_brand, ' ', i.i_category) AS brand_category,
        substring(i.i_item_desc, 1, 10) AS short_desc
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        regexp_like(i.i_item_desc, '[0-9]{3}')
        AND i.i_brand LIKE 'Brand%'
        AND p.p_channel_tv = 'Y'
        AND cs.cs_sold_date_sk = (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = (
                SELECT MAX(d_year)
                FROM date_dim
            )
            LIMIT 1
        )
)
SELECT
    brand_category,
    COUNT(DISTINCT cs_order_number) AS orders,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_quantity) AS avg_quantity,
    MIN(short_desc) AS example_short_desc
FROM filtered_sales
GROUP BY brand_category
ORDER BY total_sales DESC
LIMIT 100
