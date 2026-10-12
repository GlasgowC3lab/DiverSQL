WITH reason_agg AS (
    SELECT
        wr.wr_reason_sk,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_net_loss) AS sum_net_loss,
        AVG(wr.wr_reversed_charge) AS avg_rev_charge,
        SUM(wr.wr_return_amt_inc_tax) AS sum_return_inc_tax
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk >= 2450000
      AND wr.wr_returned_date_sk < 2450100
    GROUP BY wr.wr_reason_sk
    HAVING SUM(wr.wr_net_loss) > 50
)
SELECT
    r.r_reason_desc,
    ra.cnt_returns,
    ra.sum_net_loss,
    ra.avg_rev_charge,
    ra.sum_return_inc_tax,
    RANK() OVER (ORDER BY ra.sum_net_loss DESC) AS net_loss_rank
FROM reason_agg ra
JOIN reason r
    ON ra.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id = 'AAAAAAAABAAAAAAA'
ORDER BY net_loss_rank
LIMIT 5
