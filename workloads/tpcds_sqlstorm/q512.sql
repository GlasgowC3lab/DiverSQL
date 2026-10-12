WITH promo AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
), store_agg AS (
    SELECT
        d.d_year AS year,
        month(d.d_date) AS month_num,
        'store' AS channel,
        s.s_store_name AS channel_name,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_sales_price) AS net_sales,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN promo p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, month(d.d_date), s.s_store_name, i.i_category
), catalog_agg AS (
    SELECT
        d.d_year AS year,
        month(d.d_date) AS month_num,
        'catalog' AS channel,
        cc.cc_name AS channel_name,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_sales_price) AS net_sales,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN promo p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, month(d.d_date), cc.cc_name, i.i_category
), web_agg AS (
    SELECT
        d.d_year AS year,
        month(d.d_date) AS month_num,
        'web' AS channel,
        w.web_name AS channel_name,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS net_sales,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN promo p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, month(d.d_date), w.web_name, i.i_category
), combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)

SELECT
    c.year,
    c.month_num,
    c.channel,
    c.channel_name,
    c.category,
    c.net_profit,
    c.net_sales,
    c.quantity,
    RANK() OVER (PARTITION BY c.year, c.channel ORDER BY c.net_profit DESC) AS profit_rank,
    CUME_DIST() OVER (PARTITION BY c.year, c.channel ORDER BY c.net_profit DESC) AS profit_cume_dist,
    SUM(c.net_profit) OVER (PARTITION BY c.year, c.channel) AS total_profit,
    c.net_profit / SUM(c.net_profit) OVER (PARTITION BY c.year, c.channel) AS profit_pct
FROM combined c
WHERE c.year BETWEEN 1999 AND 2001
ORDER BY c.year, c.month_num, c.channel, profit_rank
LIMIT 200
