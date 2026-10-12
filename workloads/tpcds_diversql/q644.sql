WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_wholesale_cost,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       ss.ss_cdemo_sk,
       ss.ss_promo_sk,
       cd.cd_gender,
       cd.cd_dep_count,
       cd.cd_dep_employed_count,
       p.p_promo_name,
       p.p_channel_press,
       p.p_channel_event,
       p.p_purpose,
       p.p_cost,
       p.p_channel_tv
   FROM store_sales ss
   FULL OUTER JOIN promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN customer_demographics cd
       ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE
       (p.p_channel_press = 'N' OR p.p_channel_press IS NULL)
       AND (p.p_channel_event = 'N' OR p.p_channel_event IS NULL)
       AND (p.p_purpose = 'Unknown' OR p.p_purpose IS NULL)
       AND (ss.ss_wholesale_cost > 20 OR ss.ss_wholesale_cost IS NULL)
       AND (cd.cd_dep_count >= 2 OR cd.cd_dep_count IS NULL)
),
intersect_items AS (
   SELECT ss_item_sk FROM store_sales WHERE ss_quantity > 50
   INTERSECT
   SELECT ss_item_sk FROM store_sales WHERE ss_ext_sales_price > 1000
)
SELECT
   gender,
   SUM(profit) AS total_profit,
   SUM(cnt) AS total_transactions
FROM (
   SELECT
       b.cd_gender AS gender,
       b.p_promo_name,
       SUM(b.ss_net_profit) AS profit,
       COUNT(*) AS cnt
   FROM base b
   WHERE b.ss_item_sk IN (SELECT ss_item_sk FROM intersect_items)
     AND NOT EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_sk = b.ss_promo_sk
           AND p2.p_channel_tv = 'Y'
     )
   GROUP BY b.cd_gender, b.p_promo_name

   UNION DISTINCT

   SELECT
       b.cd_gender AS gender,
       b.p_promo_name,
       SUM(b.ss_net_profit) * 0.9 AS profit,
       COUNT(*) AS cnt
   FROM base b
   WHERE b.ss_quantity BETWEEN 10 AND 30
     AND b.p_cost > (SELECT AVG(p_cost) FROM promotion WHERE p_channel_email = 'Y')
   GROUP BY b.cd_gender, b.p_promo_name
) AS combined
GROUP BY gender
ORDER BY total_profit DESC
LIMIT 100
