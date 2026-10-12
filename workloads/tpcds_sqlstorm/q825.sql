WITH sales_agg AS (
 SELECT d.d_year,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
 UNION ALL
 SELECT d.d_year,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
 UNION ALL
 SELECT d.d_year,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
),
returns_agg AS (
 SELECT d.d_year,
        i.i_category,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
 UNION ALL
 SELECT d.d_year,
        i.i_category,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
 UNION ALL
 SELECT d.d_year,
        i.i_category,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
),
combined AS (
 SELECT s.d_year,
        s.i_category,
        s.channel,
        s.profit,
        COALESCE(r.loss, 0) AS loss,
        s.profit - COALESCE(r.loss, 0) AS net_profit
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON s.d_year = r.d_year
  AND s.i_category = r.i_category
  AND s.channel = r.channel
)
SELECT d_year,
       i_category,
       channel,
       net_profit
FROM (
  SELECT d_year,
         i_category,
         channel,
         net_profit,
         ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY net_profit DESC) AS rn
  FROM combined
) t
WHERE rn <= 10
ORDER BY channel, d_year, rn
