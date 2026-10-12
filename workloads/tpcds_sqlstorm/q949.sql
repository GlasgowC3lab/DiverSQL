WITH sales AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_paid AS net_paid,
        p.p_promo_name AS promo_name,
        'catalog' AS channel
 FROM catalog_sales cs
 INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
 UNION ALL
 SELECT ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_net_paid AS net_paid,
        p.p_promo_name AS promo_name,
        'store' AS channel
 FROM store_sales ss
 INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
 UNION ALL
 SELECT ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_net_paid AS net_paid,
        p.p_promo_name AS promo_name,
        'web' AS channel
 FROM web_sales ws
 INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
)
SELECT d.d_year,
       d.d_moy AS month,
       i.i_category,
       s.channel,
       COUNT(DISTINCT s.promo_name) AS promo_count,
       SUM(s.quantity) AS total_quantity,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.discount_amount) AS total_discount,
       SUM(s.net_profit) AS total_net_profit
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_moy, i.i_category, s.channel
ORDER BY total_net_profit DESC
LIMIT 200
