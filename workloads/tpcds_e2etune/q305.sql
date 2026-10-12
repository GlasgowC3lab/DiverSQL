WITH cat_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        c.c_current_hdemo_sk AS demo_sk,
        cr.cr_returned_date_sk AS date_sk,
        COUNT(*) AS cat_return_cnt,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        AVG(cr.cr_return_amount) AS cat_avg_return_amt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE cr.cr_returned_date_sk BETWEEN 40000 AND 50000
      AND cr.cr_reversed_charge > 0
    GROUP BY w.w_warehouse_id, w.w_city, c.c_current_hdemo_sk, cr.cr_returned_date_sk
),
web_agg AS (
    SELECT
        c.c_current_hdemo_sk AS demo_sk,
        wr.wr_returned_date_sk AS date_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        AVG(wr.wr_return_amt) AS web_avg_return_amt
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 40000 AND 50000
      AND wr.wr_fee > 0
    GROUP BY c.c_current_hdemo_sk, wr.wr_returned_date_sk
)
SELECT
    ca.w_warehouse_id,
    ca.w_city,
    ca.demo_sk,
    ca.date_sk,
    ca.cat_return_cnt,
    COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
    ca.cat_net_loss,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    (ca.cat_net_loss + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    ((ca.cat_avg_return_amt + COALESCE(wa.web_avg_return_amt, 0)) / 2.0) AS avg_return_amt_combined,
    RANK() OVER (ORDER BY (ca.cat_net_loss + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank
FROM cat_agg ca
LEFT JOIN web_agg wa
    ON ca.demo_sk = wa.demo_sk
   AND ca.date_sk = wa.date_sk
ORDER BY total_net_loss DESC
LIMIT 100
