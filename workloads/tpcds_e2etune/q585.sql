SELECT
    r.r_reason_desc,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
    RANK() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS return_amount_rank
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk IN (2450926, 2450946, 2451065, 2450954, 2451023)
  AND cr.cr_fee > 20
  AND cr.cr_return_quantity > 0
GROUP BY r.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 10
