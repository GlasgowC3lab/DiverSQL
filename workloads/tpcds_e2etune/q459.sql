WITH ws_agg AS (
    SELECT 
        ws.ws_sold_time_sk AS time_sk,
        c.c_birth_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ws.ws_sold_time_sk, c.c_birth_year
),
sr_agg AS (
    SELECT 
        sr.sr_return_time_sk AS time_sk,
        c.c_birth_year,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY sr.sr_return_time_sk, c.c_birth_year
),
wr_agg AS (
    SELECT 
        wr.wr_returned_time_sk AS time_sk,
        c.c_birth_year,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY wr.wr_returned_time_sk, c.c_birth_year
)
SELECT 
    t.t_hour,
    agg.c_birth_year,
    agg.total_net_paid,
    agg.total_net_profit,
    COALESCE(sr.total_return_loss, 0) AS total_store_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    (agg.total_net_paid - COALESCE(sr.total_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) AS net_revenue,
    agg.avg_discount,
    agg.sales_cnt,
    COALESCE(sr.return_cnt, 0) AS store_return_cnt,
    COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
    RANK() OVER (PARTITION BY t.t_hour ORDER BY (agg.total_net_paid - COALESCE(sr.total_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) DESC) AS revenue_rank
FROM ws_agg agg
JOIN time_dim t ON agg.time_sk = t.t_time_sk
LEFT JOIN sr_agg sr ON sr.time_sk = t.t_time_sk AND sr.c_birth_year = agg.c_birth_year
LEFT JOIN wr_agg wr ON wr.time_sk = t.t_time_sk AND wr.c_birth_year = agg.c_birth_year
ORDER BY t.t_hour, net_revenue DESC
LIMIT 100
