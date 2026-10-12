WITH sales_by_customer AS (
    SELECT
        ws.ws_warehouse_sk,
        w.w_state,
        w.w_city,
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_txns
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ws.ws_warehouse_sk, w.w_state, w.w_city, ws.ws_bill_customer_sk
),
returns_by_customer AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_state,
        w.w_city,
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_txns
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY cr.cr_warehouse_sk, w.w_state, w.w_city, cr.cr_refunded_customer_sk
)
SELECT
    COALESCE(s.ws_warehouse_sk, r.cr_warehouse_sk) AS warehouse_sk,
    COALESCE(s.w_state, r.w_state) AS state,
    COALESCE(s.w_city, r.w_city) AS city,
    COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
    COALESCE(s.total_paid, 0) AS total_paid,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
    COALESCE(r.total_loss, 0) AS total_loss,
    (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) AS net_impact,
    CASE
        WHEN (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) > 0 THEN 'Net Positive'
        WHEN (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) < 0 THEN 'Net Negative'
        ELSE 'Neutral'
    END AS net_impact_category,
    RANK() OVER (PARTITION BY COALESCE(s.ws_warehouse_sk, r.cr_warehouse_sk)
                 ORDER BY (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) DESC) AS customer_profit_rank,
    DENSE_RANK() OVER (ORDER BY (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) DESC) AS global_customer_dense_rank,
    SUM(COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) OVER (PARTITION BY COALESCE(s.ws_warehouse_sk, r.cr_warehouse_sk)) AS warehouse_total_net_impact
FROM sales_by_customer s
FULL OUTER JOIN returns_by_customer r
    ON s.ws_warehouse_sk = r.cr_warehouse_sk
    AND s.customer_sk = r.customer_sk
WHERE COALESCE(s.total_profit, 0) > 0 OR COALESCE(r.total_loss, 0) > 0
ORDER BY warehouse_sk, net_impact DESC
