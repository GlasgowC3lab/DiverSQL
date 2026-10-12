WITH sales_data AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    sd.channel,
    i.i_category,
    SUM(sd.net_paid) AS total_net_paid,
    SUM(sd.net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    SUM(CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_sales
FROM sales_data sd
JOIN date_dim d ON sd.date_sk = d.d_date_sk
JOIN item i ON sd.item_sk = i.i_item_sk
LEFT JOIN promotion p ON sd.promo_sk = p.p_promo_sk
WHERE d.d_year = 1998
GROUP BY d.d_year, sd.channel, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
