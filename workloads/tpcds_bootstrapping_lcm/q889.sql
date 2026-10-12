WITH catalog_agg AS (
    SELECT d.d_date_sk,
           s.s_store_sk,
           SUM(cr.cr_net_loss) AS total_cr_net_loss,
           COUNT(*) AS cnt_cr
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, s.s_store_sk
),
sales_agg AS (
    SELECT d_sold.d_date_sk AS sold_date_sk,
           s.s_store_sk,
           SUM(ws.ws_net_profit) AS total_ws_net_profit,
           AVG(ws.ws_sales_price) AS avg_ws_sales_price,
           COUNT(*) AS cnt_ws,
           AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_lag_days
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY d_sold.d_date_sk, s.s_store_sk
),
returns_agg AS (
    SELECT d.d_date_sk,
           s.s_store_sk,
           SUM(wr.wr_net_loss) AS total_wr_net_loss,
           COUNT(*) AS cnt_wr
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, s.s_store_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    COALESCE(ca.cnt_cr, 0) AS catalog_return_cnt,
    COALESCE(ca.total_cr_net_loss, 0) AS catalog_return_net_loss,
    COALESCE(ra.cnt_wr, 0) AS web_return_cnt,
    COALESCE(ra.total_wr_net_loss, 0) AS web_return_net_loss,
    COALESCE(sa.cnt_ws, 0) AS web_sales_cnt,
    COALESCE(sa.total_ws_net_profit, 0) AS web_sales_net_profit,
    COALESCE(sa.avg_ws_sales_price, 0) AS avg_web_sales_price,
    COALESCE(sa.avg_ship_lag_days, 0) AS avg_ship_lag_days,
    (COALESCE(sa.total_ws_net_profit, 0)
     - COALESCE(ca.total_cr_net_loss, 0)
     - COALESCE(ra.total_wr_net_loss, 0)) AS profit_after_returns,
    CASE
        WHEN COALESCE(sa.total_ws_net_profit, 0) <> 0 THEN
            ((COALESCE(sa.total_ws_net_profit, 0)
              - COALESCE(ca.total_cr_net_loss, 0)
              - COALESCE(ra.total_wr_net_loss, 0))
             / COALESCE(sa.total_ws_net_profit, 0)) * 100
    END AS profit_margin_percent
FROM date_dim d
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_agg ca ON ca.d_date_sk = d.d_date_sk
                         AND ca.s_store_sk = s.s_store_sk
LEFT JOIN sales_agg sa ON sa.sold_date_sk = d.d_date_sk
                        AND sa.s_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra ON ra.d_date_sk = d.d_date_sk
                         AND ra.s_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2000 AND 2005
ORDER BY profit_margin_percent DESC NULLS LAST
LIMIT 100
