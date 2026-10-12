WITH sales_union AS (
   SELECT
      'store' AS channel,
      ss_sold_date_sk AS sold_date_sk,
      ss_store_sk AS store_sk,
      ss_item_sk AS item_sk,
      ss_promo_sk AS promo_sk,
      ss_net_profit AS net_profit,
      ss_ext_sales_price AS ext_sales_price,
      ss_quantity AS quantity,
      ss_coupon_amt AS coupon_amt,
      ss_net_paid AS net_paid
   FROM store_sales
   UNION ALL
   SELECT
      'web' AS channel,
      ws_sold_date_sk AS sold_date_sk,
      NULL AS store_sk,
      ws_item_sk AS item_sk,
      ws_promo_sk AS promo_sk,
      ws_net_profit AS net_profit,
      ws_ext_sales_price AS ext_sales_price,
      ws_quantity AS quantity,
      ws_coupon_amt AS coupon_amt,
      ws_net_paid AS net_paid
   FROM web_sales
   UNION ALL
   SELECT
      'catalog' AS channel,
      cs_sold_date_sk AS sold_date_sk,
      NULL AS store_sk,
      cs_item_sk AS item_sk,
      cs_promo_sk AS promo_sk,
      cs_net_profit AS net_profit,
      cs_ext_sales_price AS ext_sales_price,
      cs_quantity AS quantity,
      cs_coupon_amt AS coupon_amt,
      cs_net_paid AS net_paid
   FROM catalog_sales
)
SELECT
   d.d_year,
   su.channel,
   COALESCE(st.s_state, 'N/A') AS state,
   i.i_brand,
   i.i_category,
   p.p_promo_name,
   SUM(su.net_profit) AS total_net_profit,
   SUM(su.ext_sales_price) AS total_sales,
   AVG(CASE WHEN su.ext_sales_price <> 0 THEN su.coupon_amt / su.ext_sales_price END) AS avg_coupon_rate,
   COUNT(*) AS sales_transactions
FROM sales_union su
JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
LEFT JOIN store st ON su.store_sk = st.s_store_sk
JOIN item i ON su.item_sk = i.i_item_sk
LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year,
         su.channel,
         COALESCE(st.s_state, 'N/A'),
         i.i_brand,
         i.i_category,
         p.p_promo_name
ORDER BY d.d_year,
         su.channel,
         total_net_profit DESC
LIMIT 100
