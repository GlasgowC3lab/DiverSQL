WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk AS site_sk,
        ws_site.web_name AS site_name,
        i.i_category AS category,
        td.t_hour AS hour,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_ext_discount_amt > 0
    GROUP BY ws.ws_web_site_sk, ws_site.web_name, i.i_category, td.t_hour
),
returns_agg AS (
    SELECT
        ws.ws_web_site_sk AS site_sk,
        ws_site.web_name AS site_name,
        i.i_category AS category,
        td.t_hour AS hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY ws.ws_web_site_sk, ws_site.web_name, i.i_category, td.t_hour
)
SELECT
    s.site_name,
    s.category,
    s.hour,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.total_profit - COALESCE(r.total_return_amt, 0) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY s.site_name, s.hour ORDER BY (s.total_profit - COALESCE(r.total_return_amt, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.site_sk = r.site_sk
    AND s.category = r.category
    AND s.hour = r.hour
ORDER BY s.site_name, s.hour, profit_rank
LIMIT 200
