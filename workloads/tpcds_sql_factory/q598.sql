WITH sales AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk, ws.ws_sold_date_sk
),
returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_returned_date_sk AS date_sk,
        SUM(sr.sr_net_loss) AS return_amount
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk
),
combined AS (
    SELECT
        COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.sales_amount, 0) AS sales_amount,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(s.sales_amount, 0) - COALESCE(r.return_amount, 0) AS net_contribution
    FROM sales s
    FULL OUTER JOIN returns r
        ON s.customer_sk = r.customer_sk
        AND s.date_sk = r.date_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    comb.date_sk,
    comb.sales_amount,
    comb.return_amount,
    comb.net_contribution,
    AVG(comb.net_contribution) OVER (PARTITION BY c.c_customer_id ORDER BY comb.date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_dates,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY comb.net_contribution DESC) AS net_contribution_rank
FROM combined comb
JOIN customer c ON comb.customer_sk = c.c_customer_sk
WHERE comb.net_contribution <> 0
ORDER BY c.c_customer_id, comb.date_sk
