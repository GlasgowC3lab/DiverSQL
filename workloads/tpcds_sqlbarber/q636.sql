SELECT
    r.r_reason_desc,
    r.r_reason_id AS reason_id,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM
    catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN (
    SELECT sr_reason_sk, sr_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk > 2452688
) sr ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    wr.wr_returned_date_sk > 2451730
GROUP BY
    r.r_reason_desc,
    r.r_reason_id
HAVING
    COUNT(*) > 5
