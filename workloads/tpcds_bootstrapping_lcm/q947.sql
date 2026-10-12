WITH sales_by_store_date AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_returns,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)

SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.total_sales,
    ws.total_profit,
    ws.sales_cnt,
    COALESCE(rt.total_returns, 0) AS total_returns,
    COALESCE(rt.total_return_loss, 0) AS total_return_loss,
    COALESCE(rt.return_cnt, 0) AS return_cnt,
    (ws.total_profit - COALESCE(rt.total_return_loss, 0)) AS net_contribution,
    ws.total_sales / NULLIF(ws.sales_cnt, 0) AS avg_sales_per_transaction,
    ws.total_profit / NULLIF(ws.sales_cnt, 0) AS avg_profit_per_transaction,
    w.web_name,
    d_open.d_date AS website_open_date,
    d_close.d_date AS website_close_date,
    d_closed.d_date AS store_closed_date
FROM sales_by_store_date ws
JOIN date_dim d_sold
    ON ws.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ws.ss_store_sk = s.s_store_sk
LEFT JOIN returns_by_date rt
    ON rt.wr_returned_date_sk = d_sold.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_open
    ON w.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON w.web_close_date_sk = d_close.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2022
ORDER BY net_contribution DESC
LIMIT 100
