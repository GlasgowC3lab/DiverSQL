SELECT d.d_year,
       i.i_category,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_profit,
       COUNT(*) AS num_sales
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid_inc_tax AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_paid_inc_tax,
           ss.ss_net_profit,
           ss.ss_promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_profit,
           ws.ws_promo_sk
    FROM web_sales ws
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON s.promo_sk = p.p_promo_sk
    AND s.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category
ORDER BY total_profit DESC
LIMIT 10
