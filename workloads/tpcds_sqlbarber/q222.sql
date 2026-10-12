SELECT i.i_item_id,
       SUM(cs.cs_net_profit) AS total_cs_profit,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       (SELECT ws_sub.ws_net_paid
        FROM web_sales ws_sub
        WHERE ws_sub.ws_sold_date_sk = 2451706
        LIMIT 1) AS sample_ws_net_paid
FROM catalog_sales cs
INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN item i ON p.p_item_sk = i.i_item_sk
INNER JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
WHERE cs.cs_sold_date_sk = 2450826
GROUP BY i.i_item_id
HAVING SUM(cs.cs_net_profit) > 1662.84
