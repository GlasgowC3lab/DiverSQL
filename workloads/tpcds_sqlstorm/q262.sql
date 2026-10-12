SELECT d.d_year,
       i.i_category,
       COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
       SUM(s.sale_amount) AS total_sales,
       SUM(s.sale_profit) AS total_profit,
       AVG(s.sale_discount) AS avg_discount
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sale_amount,
           cs.cs_net_profit AS sale_profit,
           cs.cs_ext_discount_amt AS sale_discount,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_promo_sk
    FROM web_sales ws
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           ss.ss_promo_sk
    FROM store_sales ss
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category, COALESCE(p.p_promo_name, 'No Promo')
ORDER BY d.d_year, i.i_category, total_sales DESC
