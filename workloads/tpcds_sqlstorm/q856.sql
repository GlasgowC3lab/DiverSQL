WITH sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_customer_sk AS customer_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           ss_promo_sk AS promo_sk
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_bill_customer_sk,
           cs_quantity,
           cs_net_paid,
           cs_net_profit,
           cs_promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_quantity,
           ws_net_paid,
           ws_net_profit,
           ws_promo_sk
    FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       p.p_channel_catalog AS promo_channel,
       SUM(s.net_paid) AS total_sales,
       SUM(s.net_profit) AS total_profit,
       COUNT(DISTINCT s.customer_sk) AS unique_customers,
       AVG(s.quantity) AS avg_quantity,
       SUM(CASE WHEN p.p_discount_active = 'Y' THEN s.net_paid ELSE 0 END) AS discount_active_sales
FROM sales_union s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, i.i_category, p.p_channel_catalog
HAVING SUM(s.net_paid) > 100000
ORDER BY d.d_year, i.i_category, p.p_channel_catalog
