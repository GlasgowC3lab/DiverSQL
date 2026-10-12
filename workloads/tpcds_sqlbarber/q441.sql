SELECT
    r.r_reason_desc,
    ca.ca_state,
    SUM(sr.sr_return_amt) AS total_return_amt,
    (SELECT 0) AS placeholder_val
FROM store_returns sr
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc, ca.ca_state
HAVING COUNT(*) > 500
