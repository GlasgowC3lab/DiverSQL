SELECT d.d_year,
       d.d_month_seq,
       COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
       SUM(f.net_paid) AS total_net_paid,
       SUM(f.net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count
FROM (
    SELECT cs_sold_date_sk AS date_sk,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_net_paid,
           ss_net_profit,
           ss_promo_sk,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_net_paid,
           ws_net_profit,
           ws_promo_sk,
           'web'
    FROM web_sales
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
LEFT JOIN promotion p ON f.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year,
         d.d_month_seq,
         COALESCE(p.p_promo_name, 'No Promotion')
ORDER BY d.d_year,
         d.d_month_seq,
         total_net_paid DESC
