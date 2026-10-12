WITH sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
non_returned_orders AS (
    SELECT ws_order_number
    FROM sampled_ws
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
joined_data AS (
    SELECT
        d.d_year AS d_year,
        r.r_reason_desc AS r_reason_desc,
        c.c_customer_id AS c_customer_id,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        SUM(sr.sr_net_loss) OVER (
            PARTITION BY sr.sr_customer_sk
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN sampled_ws ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Did not like the warranty'
      AND sr.sr_net_loss > 100
)
SELECT
    d_year,
    r_reason_desc,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(ws_net_profit) AS avg_net_profit,
    MAX(running_loss) AS max_running_loss,
    (SELECT COUNT(*) FROM non_returned_orders) AS non_returned_order_count
FROM joined_data
GROUP BY d_year, r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
