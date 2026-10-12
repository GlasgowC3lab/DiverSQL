WITH all_sales AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         ss_item_sk AS item_sk,
         ss_customer_sk AS customer_sk,
         ss_cdemo_sk AS cdemo_sk,
         ss_hdemo_sk AS hdemo_sk,
         ss_promo_sk AS promo_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_item_sk,
         cs_bill_customer_sk,
         cs_bill_cdemo_sk,
         cs_bill_hdemo_sk,
         cs_promo_sk,
         cs_quantity,
         cs_net_paid,
         cs_net_profit,
         'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_bill_customer_sk,
         ws_bill_cdemo_sk,
         ws_bill_hdemo_sk,
         ws_promo_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         'web'
  FROM web_sales
),
agg_sales AS (
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         s.channel,
         cd.cd_gender,
         hd.hd_buy_potential,
         SUM(s.quantity) AS total_quantity,
         SUM(s.net_paid) AS total_net_paid,
         SUM(s.net_profit) AS total_net_profit,
         AVG(CASE WHEN s.net_paid <> 0 THEN s.net_profit / s.net_paid END) AS avg_profit_margin,
         COUNT(DISTINCT s.customer_sk) AS distinct_customers
  FROM all_sales s
  JOIN date_dim d ON d.d_date_sk = s.sold_date_sk
  JOIN item i ON i.i_item_sk = s.item_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = s.cdemo_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = s.hdemo_sk
  LEFT JOIN promotion p ON p.p_promo_sk = s.promo_sk
  GROUP BY d.d_year, i.i_category, i.i_brand, s.channel, cd.cd_gender, hd.hd_buy_potential
  HAVING SUM(s.net_profit) > 0
)
SELECT a.*,
       RANK() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_net_profit DESC) AS profit_rank,
       LAG(a.total_net_profit) OVER (PARTITION BY a.i_category, a.i_brand, a.channel ORDER BY a.d_year) AS prev_year_profit,
       (a.total_net_profit - LAG(a.total_net_profit) OVER (PARTITION BY a.i_category, a.i_brand, a.channel ORDER BY a.d_year)) /
         NULLIF(LAG(a.total_net_profit) OVER (PARTITION BY a.i_category, a.i_brand, a.channel ORDER BY a.d_year), 0) AS profit_growth_rate
FROM agg_sales a
ORDER BY a.d_year, a.channel, profit_rank
LIMIT 200
