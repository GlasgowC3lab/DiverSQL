WITH sales_agg AS (
    SELECT date_sk, item_sk, SUM(net_profit) AS profit
    FROM (
        SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_net_profit
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_profit
        FROM web_sales ws
    ) s
    GROUP BY date_sk, item_sk
),
returns_agg AS (
    SELECT date_sk, item_sk, SUM(net_loss) AS loss
    FROM (
        SELECT cr.cr_returned_date_sk AS date_sk, cr.cr_item_sk AS item_sk, cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_returned_date_sk, sr.sr_item_sk, sr.sr_net_loss
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_returned_date_sk, wr.wr_item_sk, wr.wr_net_loss
        FROM web_returns wr
    ) r
    GROUP BY date_sk, item_sk
)
SELECT d.d_year,
       d.d_month_seq,
       SUM(COALESCE(s.profit, 0) - COALESCE(r.loss, 0)) AS net_gain,
       COUNT(DISTINCT s.item_sk) AS distinct_items_sold
FROM sales_agg s
LEFT JOIN returns_agg r ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
JOIN date_dim d ON s.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
