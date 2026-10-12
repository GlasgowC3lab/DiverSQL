WITH sales_agg AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         sum(cs.cs_net_paid) AS net_paid,
         sum(cs.cs_net_profit) AS profit,
         sum(cs.cs_ext_discount_amt) AS discount,
         count(DISTINCT cs.cs_order_number) AS orders,
         sum(coalesce(p.p_cost, 0)) AS promo_cost,
         'catalog' AS channel
  FROM catalog_sales cs
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk

  UNION ALL

  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_item_sk AS item_sk,
         sum(ss.ss_net_paid) AS net_paid,
         sum(ss.ss_net_profit) AS profit,
         sum(ss.ss_ext_discount_amt) AS discount,
         count(DISTINCT ss.ss_ticket_number) AS orders,
         sum(coalesce(p.p_cost, 0)) AS promo_cost,
         'store' AS channel
  FROM store_sales ss
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk

  UNION ALL

  SELECT ws.ws_sold_date_sk AS date_sk,
         ws.ws_item_sk AS item_sk,
         sum(ws.ws_net_paid) AS net_paid,
         sum(ws.ws_net_profit) AS profit,
         sum(ws.ws_ext_discount_amt) AS discount,
         count(DISTINCT ws.ws_order_number) AS orders,
         sum(coalesce(p.p_cost, 0)) AS promo_cost,
         'web' AS channel
  FROM web_sales ws
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
joined AS (
  SELECT d.d_year AS sale_year,
         d.d_month_seq AS sale_month,
         i.i_item_id,
         i.i_product_name,
         s.channel,
         sum(s.net_paid) AS total_net_paid,
         sum(s.profit) AS total_profit,
         sum(s.discount) AS total_discount,
         sum(s.orders) AS total_orders,
         sum(s.promo_cost) AS total_promo_cost
  FROM sales_agg s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name, s.channel
)
SELECT
  sale_year,
  sale_month,
  channel,
  i_item_id,
  i_product_name,
  total_net_paid,
  total_profit,
  total_discount,
  total_orders,
  total_promo_cost,
  total_net_paid - total_promo_cost AS net_paid_excl_promo,
  total_net_paid / nullif(total_orders, 0) AS avg_spend_per_order,
  total_discount / nullif(total_net_paid, 0) AS discount_rate,
  total_promo_cost / nullif(total_orders, 0) AS avg_promo_cost_per_order
FROM (
  SELECT
    *,
    row_number() OVER (PARTITION BY sale_year, sale_month, channel ORDER BY total_net_paid DESC) AS rn
  FROM joined
) t
WHERE rn <= 10
ORDER BY sale_year, sale_month, channel, total_net_paid DESC
