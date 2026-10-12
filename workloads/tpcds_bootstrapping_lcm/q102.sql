SELECT
    cc.cc_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fee,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cc.cc_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND cr.cr_net_loss > 0
GROUP BY GROUPING SETS (
    (cc.cc_name, s.s_store_name, d.d_year, d.d_month_seq),
    (cc.cc_name, s.s_store_name, d.d_year),
    (cc.cc_name, s.s_store_name),
    (cc.cc_name),
    (s.s_store_name)
)
ORDER BY total_net_loss DESC
LIMIT 100
