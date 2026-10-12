WITH sales AS (
    SELECT
        w.w_state AS state,
        date_trunc('month', DATE '1970-01-01' + cs.cs_sold_date_sk * INTERVAL '1' DAY) AS month,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
    GROUP BY w.w_state, date_trunc('month', DATE '1970-01-01' + cs.cs_sold_date_sk * INTERVAL '1' DAY)
    UNION ALL
    SELECT
        w.w_state AS state,
        date_trunc('month', DATE '1970-01-01' + ws.ws_sold_date_sk * INTERVAL '1' DAY) AS month,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450826
    GROUP BY w.w_state, date_trunc('month', DATE '1970-01-01' + ws.ws_sold_date_sk * INTERVAL '1' DAY)
),
returns AS (
    SELECT
        date_trunc('month', DATE '1970-01-01' + sr.sr_returned_date_sk * INTERVAL '1' DAY) AS month,
        r.r_reason_desc AS reason,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450820 AND 2450826
    GROUP BY date_trunc('month', DATE '1970-01-01' + sr.sr_returned_date_sk * INTERVAL '1' DAY), r.r_reason_desc
)
SELECT
    s.state,
    s.month,
    s.total_net_paid,
    s.total_profit,
    s.avg_discount,
    s.order_cnt,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    r.reason AS top_return_reason,
    RANK() OVER (PARTITION BY s.month ORDER BY s.total_profit DESC) AS profit_state_rank
FROM sales s
LEFT JOIN (
    SELECT month, reason, total_return_amount, total_return_loss, return_cnt,
           ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_return_loss DESC) AS rn
    FROM returns
) r ON s.month = r.month AND r.rn = 1
WHERE s.state IS NOT NULL
ORDER BY s.month, profit_state_rank
LIMIT 100
