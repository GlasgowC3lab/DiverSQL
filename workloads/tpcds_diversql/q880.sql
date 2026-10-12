/* Goal: Compare total sales by item category/brand across catalog and web channels, applying regex filters on item descriptions and promotion names, and showcasing string processing, lateral subqueries, and a right outer join to retain all items. */
WITH promo_filtered AS (
    SELECT p_promo_sk, p_promo_name
    FROM promotion
    WHERE regexp_like(p_promo_name, '^.*Discount.*$')
)
SELECT
    i.i_category            AS category,
    i.i_brand               AS brand,
    promo.p_promo_name      AS promo_name,
    SUM(cs.cs_ext_sales_price)          AS total_sales,
    COUNT(DISTINCT cs.cs_order_number)  AS order_cnt,
    MIN(cs.cs_sold_date_sk)              AS first_sold_date_sk,
    MAX(cs.cs_sold_date_sk)              AS last_sold_date_sk,
    dw.first_word_desc                   AS extra_info
FROM
    catalog_sales cs
    RIGHT OUTER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promo_filtered promo
        ON cs.cs_promo_sk = promo.p_promo_sk
    LEFT JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(i.i_item_desc, '([A-Za-z]+)') AS first_word_desc
    ) dw
WHERE
    (i.i_color LIKE 'red%' OR i.i_color LIKE 'pale%')
    AND regexp_like(i.i_item_desc, '\\d{3}')
    AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
    )
GROUP BY
    i.i_category,
    i.i_brand,
    promo.p_promo_name,
    dw.first_word_desc

UNION

SELECT
    i2.i_category           AS category,
    i2.i_brand              AS brand,
    promo2.p_promo_name     AS promo_name,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    COUNT(DISTINCT ws.ws_order_number)  AS order_cnt,
    MIN(ws.ws_sold_date_sk)              AS first_sold_date_sk,
    MAX(ws.ws_sold_date_sk)              AS last_sold_date_sk,
    wp_l.wp_url_prefix                   AS extra_info
FROM
    web_sales ws
    RIGHT OUTER JOIN item i2
        ON ws.ws_item_sk = i2.i_item_sk
    LEFT JOIN promotion promo2
        ON ws.ws_promo_sk = promo2.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT substr(wp.wp_url, 1, 15) AS wp_url_prefix
    ) wp_l
WHERE
    wp.wp_type LIKE 'article%'
    AND regexp_like(promo2.p_promo_name, '.*Clearance.*')
    AND ws.ws_ext_sales_price > 0
GROUP BY
    i2.i_category,
    i2.i_brand,
    promo2.p_promo_name,
    wp_l.wp_url_prefix

ORDER BY
    total_sales DESC
LIMIT 100
