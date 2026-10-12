WITH sales_agg AS (
    SELECT cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cs_net_profit) AS profit,
           SUM(cs_quantity) AS quantity
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
    UNION ALL
    SELECT ss_sold_date_sk,
           'store',
           SUM(ss_net_profit),
           SUM(ss_quantity)
    FROM store_sales
    GROUP BY ss_sold_date_sk
    UNION ALL
    SELECT ws_sold_date_sk,
           'web',
           SUM(ws_net_profit),
           SUM(ws_quantity)
    FROM web_sales
    GROUP BY ws_sold_date_sk
), returns_agg AS (
    SELECT cr_returned_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cr_net_loss) AS loss,
           SUM(cr_return_quantity) AS quantity
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
    UNION ALL
    SELECT sr_returned_date_sk,
           'store',
           SUM(sr_net_loss),
           SUM(sr_return_quantity)
    FROM store_returns
    GROUP BY sr_returned_date_sk
    UNION ALL
    SELECT wr_returned_date_sk,
           'web',
           SUM(wr_net_loss),
           SUM(wr_return_quantity)
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT d.d_year,
       s.channel,
       SUM(COALESCE(s.profit, 0) - COALESCE(r.loss, 0)) AS net_profit,
       SUM(COALESCE(s.quantity, 0) - COALESCE(r.quantity, 0)) AS net_quantity
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.date_sk = r.date_sk AND s.channel = r.channel
JOIN date_dim d
  ON s.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, s.channel
ORDER BY d.d_year, s.channel
