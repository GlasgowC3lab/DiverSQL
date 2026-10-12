SELECT
    c.c_customer_id,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_net_loss > 500
  AND c.c_last_review_date = 2452529
GROUP BY c.c_customer_id
HAVING SUM(cr.cr_return_amount) > 200
