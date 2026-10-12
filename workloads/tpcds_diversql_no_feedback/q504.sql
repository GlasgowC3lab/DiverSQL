WITH date_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year = 2002
      AND d_month_seq BETWEEN 1200 AND 1220
),
returns_filtered AS (
    SELECT cr_order_number,
           cr_return_amount,
           cr_refunded_cash,
           cr_reason_sk,
           cr_returned_date_sk,
           cr_return_quantity
    FROM catalog_returns
    WHERE cr_refunded_cash > 500
      AND cr_return_quantity > 1
),
reasons_filtered AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_id = 'AAAAAAAABBAAAAAA'
),
web_sales_filtered AS (
    SELECT ws_order_number,
           ws_sales_price,
           ws_net_paid,
           ws_sold_date_sk,
           ws_ship_hdemo_sk
    FROM web_sales
    WHERE ws_sales_price < 100
      AND ws_ship_hdemo_sk = 4106
),
order_numbers_except AS (
    SELECT cr_order_number AS order_num FROM returns_filtered
    EXCEPT
    SELECT ws_order_number FROM web_sales_filtered
)
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_net_paid) AS avg_web_net_paid,
    COUNT(DISTINCT o.order_num) AS returns_without_web_orders
FROM date_filtered d
RIGHT OUTER JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns_filtered cr
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN reasons_filtered r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales_filtered ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN order_numbers_except o
    ON cr.cr_order_number = o.order_num
WHERE d.d_date IS NOT NULL
GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
ORDER BY total_store_profit DESC
LIMIT 100
