WITH call_center_tax AS (
    SELECT avg(cc_tax_percentage) AS avg_tax_pct
    FROM call_center
    WHERE cc_rec_start_date >= DATE '2000-01-01'
      AND cc_mkt_id IN (2, 3)
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    (SELECT avg_tax_pct FROM call_center_tax) AS avg_call_center_tax_pct
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE sr.sr_returned_date_sk BETWEEN 20000101 AND 20001231
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
