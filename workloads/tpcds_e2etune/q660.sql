WITH agg_returns AS (
    SELECT
        r.r_reason_desc AS reason,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_quantity) AS total_qty,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'Product'
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_marital_status
    HAVING COUNT(*) >= 10
)
SELECT
    reason,
    gender,
    marital_status,
    return_cnt,
    total_qty,
    avg_net_loss,
    total_return_amount,
    avg_return_amount,
    RANK() OVER (ORDER BY total_return_amount DESC) AS amount_rank
FROM agg_returns
ORDER BY total_return_amount DESC
LIMIT 100
