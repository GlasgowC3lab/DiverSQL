WITH unified_sales AS (
   SELECT cs_sold_date_sk AS date_sk,
          cs_item_sk AS item_sk,
          cs_net_profit AS net_profit,
          cs_net_paid_inc_tax AS net_paid,
          cs_ext_discount_amt AS discount_amt,
          cs_quantity AS quantity,
          'catalog' AS channel
   FROM catalog_sales
   UNION ALL
   SELECT ss_sold_date_sk,
          ss_item_sk,
          ss_net_profit,
          ss_net_paid_inc_tax,
          ss_ext_discount_amt,
          ss_quantity,
          'store'
   FROM store_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_net_profit,
          ws_net_paid_inc_tax,
          ws_ext_discount_amt,
          ws_quantity,
          'web'
   FROM web_sales
), sales_with_date AS (
   SELECT us.*,
          d.d_year AS year
   FROM unified_sales us
   JOIN date_dim d ON us.date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
), sales_enriched AS (
   SELECT swd.*,
          i.i_category,
          i.i_class
   FROM sales_with_date swd
   JOIN item i ON swd.item_sk = i.i_item_sk
), agg AS (
   SELECT year,
          channel,
          i_category AS category,
          SUM(net_profit) AS total_net_profit,
          SUM(net_paid) AS total_net_paid,
          SUM(quantity) AS total_quantity,
          SUM(discount_amt) / NULLIF(SUM(quantity), 0) AS avg_discount_per_unit
   FROM sales_enriched
   GROUP BY year, channel, i_category
), growth AS (
   SELECT a.*,
          LAG(total_net_profit) OVER (PARTITION BY channel, category ORDER BY year) AS prev_year_profit,
          CASE
              WHEN LAG(total_net_profit) OVER (PARTITION BY channel, category ORDER BY year) IS NULL
                   OR LAG(total_net_profit) OVER (PARTITION BY channel, category ORDER BY year) = 0 THEN NULL
              ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY channel, category ORDER BY year)) * 100.0
                   / LAG(total_net_profit) OVER (PARTITION BY channel, category ORDER BY year)
          END AS yoy_profit_pct,
          SUM(total_net_profit) OVER (PARTITION BY channel ORDER BY year
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
          DENSE_RANK() OVER (PARTITION BY year, channel ORDER BY total_net_profit DESC) AS category_rank
   FROM agg a
)
SELECT year,
       channel,
       category,
       total_net_profit,
       total_net_paid,
       total_quantity,
       avg_discount_per_unit,
       yoy_profit_pct,
       cumulative_profit,
       category_rank
FROM growth
WHERE category_rank <= 5
ORDER BY year, channel, category_rank
