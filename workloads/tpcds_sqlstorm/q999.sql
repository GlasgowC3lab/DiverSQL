WITH all_sales AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_store_sk AS location_sk,
           ss.ss_promo_sk AS promo_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog',
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_call_center_sk,
           cs.cs_promo_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web',
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_web_page_sk,
           ws.ws_promo_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
), enriched_sales AS (
    SELECT s.channel,
           s.date_sk,
           s.item_sk,
           s.location_sk,
           s.promo_sk,
           s.quantity,
           s.net_paid,
           s.net_profit,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           p.p_promo_name AS promo_name
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1997 AND 1998
), aggregated_sales AS (
    SELECT d_year,
           d_month_seq,
           channel,
           i_category,
           i_brand,
           promo_name,
           SUM(quantity) AS total_quantity,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit
    FROM enriched_sales
    GROUP BY d_year, d_month_seq, channel, i_category, i_brand, promo_name
)
SELECT d_year,
       d_month_seq,
       channel,
       i_category,
       i_brand,
       promo_name,
       total_quantity,
       total_net_paid,
       total_net_profit,
       RANK() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_net_paid DESC) AS sales_rank
FROM aggregated_sales
WHERE total_net_paid > 50000
ORDER BY d_year, d_month_seq, channel, sales_rank
FETCH FIRST 200 ROWS ONLY
