WITH sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(ss.ss_net_profit)
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           SUM(ws.ws_net_profit)
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
), sales_total AS (
    SELECT category, year, month_seq, SUM(profit) AS profit
    FROM sales_agg
    GROUP BY category, year, month_seq
), returns_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           -SUM(cr.cr_net_loss) AS profit
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           -SUM(sr.sr_net_loss)
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.i_category,
           d.d_year,
           d.d_month_seq,
           -SUM(wr.wr_net_loss)
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
), returns_total AS (
    SELECT category, year, month_seq, SUM(profit) AS profit
    FROM returns_agg
    GROUP BY category, year, month_seq
)
SELECT COALESCE(s.category, r.category) AS category,
       COALESCE(s.year, r.year) AS year,
       COALESCE(s.month_seq, r.month_seq) AS month_seq,
       COALESCE(s.profit, 0) + COALESCE(r.profit, 0) AS total_profit
FROM sales_total s
FULL OUTER JOIN returns_total r
    ON s.category = r.category
    AND s.year = r.year
    AND s.month_seq = r.month_seq
ORDER BY total_profit DESC
LIMIT 100
