SELECT i_brand, i_category, p_promo_name,
       SUM(ws_ext_sales_price) AS total_sales,
       AVG(ws_net_profit) AS avg_profit
FROM web_sales
INNER JOIN item ON web_sales.ws_item_sk = item.i_item_sk
INNER JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
WHERE i_current_price > 7.86
  AND ws_sold_date_sk BETWEEN 2451517 AND 2451150
GROUP BY i_brand, i_category, p_promo_name
