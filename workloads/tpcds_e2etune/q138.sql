WITH web_sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_warehouse_sk, d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY ws.ws_warehouse_sk, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    w.w_warehouse_name,
    ws_agg.d_year,
    ws_agg.d_month_seq,
    ws_agg.total_net_paid,
    ws_agg.total_net_profit,
    COALESCE(wr_agg.total_return_loss, 0) AS total_web_return_loss,
    COALESCE(st_agg.total_store_return_loss, 0) AS total_store_return_loss,
    ws_agg.total_net_profit - COALESCE(wr_agg.total_return_loss, 0) - COALESCE(st_agg.total_store_return_loss, 0) AS net_profit_after_returns,
    RANK() OVER (
        PARTITION BY ws_agg.d_year
        ORDER BY (ws_agg.total_net_profit - COALESCE(wr_agg.total_return_loss, 0) - COALESCE(st_agg.total_store_return_loss, 0)) DESC
    ) AS profit_rank
FROM web_sales_agg ws_agg
LEFT JOIN web_returns_agg wr_agg
    ON ws_agg.ws_warehouse_sk = wr_agg.ws_warehouse_sk
   AND ws_agg.d_year = wr_agg.d_year
   AND ws_agg.d_month_seq = wr_agg.d_month_seq
LEFT JOIN store_returns_agg st_agg
    ON ws_agg.d_year = st_agg.d_year
   AND ws_agg.d_month_seq = st_agg.d_month_seq
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws_agg.d_year = 2001
  AND ws_agg.d_month_seq BETWEEN 1 AND 12
ORDER BY net_profit_after_returns DESC
LIMIT 100
