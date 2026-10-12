WITH agg AS (
    SELECT
        s.s_store_name AS store_name,
        cd.cd_education_status AS education_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cd.cd_purchase_estimate >= 1500
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND s.s_state = 'CA'
    GROUP BY s.s_store_name, cd.cd_education_status
    HAVING SUM(sr.sr_return_amt_inc_tax) > 10000
)
SELECT
    store_name,
    education_status,
    num_returns,
    total_return_amount,
    avg_return_qty,
    total_net_loss,
    RANK() OVER (PARTITION BY education_status ORDER BY total_return_amount DESC) AS rank_within_education
FROM agg
ORDER BY total_return_amount DESC
LIMIT 10
