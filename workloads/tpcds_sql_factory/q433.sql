SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    ca_ref.ca_city AS refunded_city,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'Critical'
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_severity,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM catalog_returns cr
INNER JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
GROUP BY
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    ca_ref.ca_city
