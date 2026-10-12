SELECT
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_store_credit) AS total_store_credit,
    AVG(sr.sr_return_amt) AS avg_return_amount
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE cd.cd_gender = 'F'
  AND c.c_birth_year > 1950
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND r.r_reason_desc LIKE '%defect%'
  AND wp.wp_type = 'Landing'
GROUP BY i.i_category, i.i_brand, r.r_reason_desc
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 20
