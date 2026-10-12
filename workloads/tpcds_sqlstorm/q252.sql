WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS channel_sk,
        'catalog' AS channel_type,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        'store',
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        'web',
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_promo_sk
    FROM web_sales ws
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    CASE
        WHEN us.channel_type = 'catalog' THEN cc.cc_name
        WHEN us.channel_type = 'store' THEN s.s_store_name
        WHEN us.channel_type = 'web' THEN wp.wp_url
    END AS channel_name,
    COUNT(DISTINCT us.promo_sk) AS distinct_promotions,
    SUM(us.ext_sales_price) AS total_sales,
    SUM(us.ext_discount_amt) AS total_discount,
    SUM(us.net_profit) AS total_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN us.ext_sales_price ELSE 0 END) AS discount_active_sales
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
LEFT JOIN call_center cc ON us.channel_type = 'catalog' AND us.channel_sk = cc.cc_call_center_sk
LEFT JOIN store s ON us.channel_type = 'store' AND us.channel_sk = s.s_store_sk
LEFT JOIN web_page wp ON us.channel_type = 'web' AND us.channel_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_year,
    i.i_category,
    i.i_brand,
    CASE
        WHEN us.channel_type = 'catalog' THEN cc.cc_name
        WHEN us.channel_type = 'store' THEN s.s_store_name
        WHEN us.channel_type = 'web' THEN wp.wp_url
    END
ORDER BY d.d_year, total_sales DESC
LIMIT 100
