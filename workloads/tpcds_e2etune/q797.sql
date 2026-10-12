WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_bill_cdemo_sk,
        d.d_year,
        d.d_month_seq,
        cp.cp_department AS cp_department,
        cd.cd_gender AS cd_gender
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_fee,
        d.d_year AS return_year,
        d.d_month_seq AS return_month,
        cp.cp_department AS return_department,
        cd.cd_gender AS return_gender
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
)
SELECT
    s.cp_department AS department,
    s.d_year AS year,
    s.d_month_seq AS month,
    s.cd_gender AS gender,
    SUM(s.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(r.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.wr_fee), 0) AS total_return_fee,
    SUM(s.ws_net_profit) - COALESCE(SUM(r.wr_return_amt), 0) - COALESCE(SUM(r.wr_fee), 0) AS net_profit_after_returns,
    COUNT(DISTINCT s.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT r.wr_order_number) AS distinct_return_orders
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
GROUP BY s.cp_department, s.d_year, s.d_month_seq, s.cd_gender
HAVING SUM(s.ws_net_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
