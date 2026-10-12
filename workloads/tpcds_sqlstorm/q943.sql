WITH ss_agg AS (
   SELECT d.d_year,
          i.i_category,
          SUM(ss.ss_net_profit) AS ss_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
ss_ret AS (
   SELECT d.d_year,
          i.i_category,
          SUM(sr.sr_net_loss) AS sr_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
ws_agg AS (
   SELECT d.d_year,
          i.i_category,
          SUM(ws.ws_net_profit) AS ws_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
ws_ret AS (
   SELECT d.d_year,
          i.i_category,
          SUM(wr.wr_net_loss) AS wr_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
cs_agg AS (
   SELECT d.d_year,
          i.i_category,
          SUM(cs.cs_net_profit) AS cs_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
cs_ret AS (
   SELECT d.d_year,
          i.i_category,
          SUM(cr.cr_net_loss) AS cr_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   GROUP BY d.d_year, i.i_category
),
keys AS (
   SELECT d_year AS sales_year, i_category AS category FROM ss_agg
   UNION
   SELECT d_year, i_category FROM ws_agg
   UNION
   SELECT d_year, i_category FROM cs_agg
),
combined AS (
   SELECT
      k.sales_year,
      k.category,
      COALESCE(ss.ss_profit, 0) + COALESCE(ws.ws_profit, 0) + COALESCE(cs.cs_profit, 0) -
      COALESCE(sr.sr_loss, 0) - COALESCE(wr.wr_loss, 0) - COALESCE(cr.cr_loss, 0) AS net_profit
   FROM keys k
   LEFT JOIN ss_agg ss ON ss.d_year = k.sales_year AND ss.i_category = k.category
   LEFT JOIN ws_agg ws ON ws.d_year = k.sales_year AND ws.i_category = k.category
   LEFT JOIN cs_agg cs ON cs.d_year = k.sales_year AND cs.i_category = k.category
   LEFT JOIN ss_ret sr ON sr.d_year = k.sales_year AND sr.i_category = k.category
   LEFT JOIN ws_ret wr ON wr.d_year = k.sales_year AND wr.i_category = k.category
   LEFT JOIN cs_ret cr ON cr.d_year = k.sales_year AND cr.i_category = k.category
)
SELECT
   sales_year,
   category,
   net_profit,
   ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY net_profit DESC) AS rank_by_profit,
   AVG(net_profit) OVER (PARTITION BY category ORDER BY sales_year ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS profit_5yr_moving_avg
FROM combined
WHERE sales_year >= 1998
ORDER BY sales_year, net_profit DESC
LIMIT 200
