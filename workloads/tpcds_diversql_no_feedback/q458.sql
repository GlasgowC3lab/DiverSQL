SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_number,
    cd.cd_gender,
    ca.ca_city,
    cr.cr_return_amount,
    wr.wr_return_amt,
    lt.total_catalog_return_amount,
    (cr.cr_return_amount + wr.wr_return_amt) AS total_combined_return,
    CASE WHEN cd.cd_purchase_estimate > 8000 THEN 'HIGH' ELSE 'LOW' END AS purchase_category,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY (cr.cr_return_amount + wr.wr_return_amt) DESC) AS state_rank,
    ROW_NUMBER() OVER (ORDER BY (cr.cr_return_amount + wr.wr_return_amt) DESC) AS overall_rank
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web_returns wr
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
CROSS JOIN LATERAL (
    SELECT sum(cr2.cr_return_amount) AS total_catalog_return_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cr.cr_order_number
) lt
WHERE cd.cd_purchase_estimate > 5000
  AND ca.ca_state = 'CA'
  AND cp.cp_department = 'DEPARTMENT'
LIMIT 100
