WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
)
SELECT
    d.d_year,
    d.d_quarter_seq,
    p.p_promo_name,
    SUM(u.net_paid) AS total_net_paid,
    SUM(u.net_profit) AS total_net_profit,
    COUNT(DISTINCT u.item_sk) AS distinct_items_sold
FROM unified_sales u
JOIN date_dim d ON u.sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_quarter_seq, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 50
