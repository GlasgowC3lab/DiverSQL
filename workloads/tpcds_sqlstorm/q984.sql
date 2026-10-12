WITH
store_sales_agg AS (
 SELECT d.d_year,
        d.d_quarter_seq,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_discount_amt) AS discount_amount,
        COUNT(*) AS order_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
catalog_sales_agg AS (
 SELECT d.d_year,
        d.d_quarter_seq,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_discount_amt) AS discount_amount,
        COUNT(*) AS order_count
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_sales_agg AS (
 SELECT d.d_year,
        d.d_quarter_seq,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_discount_amt) AS discount_amount,
        COUNT(*) AS order_count
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
combined AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
aggregated AS (
 SELECT
   year,
   quarter,
   category,
   channel,
   net_paid,
   net_profit,
   discount_amount,
   order_count,
   net_profit / NULLIF(net_paid, 0) AS profit_margin,
   net_paid / NULLIF(order_count, 0) AS avg_net_paid_per_order,
   SUM(net_profit) OVER (PARTITION BY year, category ORDER BY quarter ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
   RANK() OVER (PARTITION BY year, category ORDER BY net_profit DESC) AS profit_rank
 FROM (
   SELECT
     d_year AS year,
     d_quarter_seq AS quarter,
     i_category AS category,
     channel,
     net_paid,
     net_profit,
     discount_amount,
     order_count
   FROM combined
 ) t
)
SELECT *
FROM aggregated
WHERE year BETWEEN 2000 AND 2002
ORDER BY year, quarter, category, profit_rank
LIMIT 100
