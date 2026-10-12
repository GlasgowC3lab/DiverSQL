/*
Goal: Identify web page identifiers with high sales where the page key matches a specific pattern, compute aggregated sales and return metrics, and keep only those rows that have at least one related return record with a fee greater than 20.
*/
WITH joined AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_refunded_cdemo_sk,
        CAST(ws.ws_web_page_sk AS VARCHAR) AS ws_web_page_sk_str
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
       AND ws.ws_order_number = wr.wr_order_number
    WHERE regexp_like(CAST(ws.ws_web_page_sk AS VARCHAR), '^1[0-9]{2}$')
      AND CAST(ws.ws_web_page_sk AS VARCHAR) LIKE '12%'
)
SELECT
    ws_web_page_sk,
    COUNT(*) AS orders_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(ws_net_profit) AS avg_net_profit,
    MIN(wr_fee) AS min_fee,
    MAX(wr_fee) AS max_fee
FROM joined j
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_cdemo_sk = j.wr_refunded_cdemo_sk
      AND wr2.wr_fee > 20
)
GROUP BY ws_web_page_sk
ORDER BY total_sales DESC
LIMIT 100
