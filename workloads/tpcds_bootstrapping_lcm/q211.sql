SELECT
    d.d_date AS return_date,
    d.d_day_name,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cr.cr_returning_customer_sk)      AS catalog_returning_customers,
    SUM(cr.cr_net_loss)                             AS total_catalog_net_loss,
    COUNT(DISTINCT wr.wr_returning_customer_sk)     AS web_returning_customers,
    SUM(wr.wr_net_loss)                             AS total_web_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) = 0 THEN NULL
        ELSE SUM(wr.wr_net_loss) / SUM(cr.cr_net_loss)
    END                                            AS web_to_catalog_loss_ratio,
    COUNT(DISTINCT ca_refunded.ca_address_id)      AS distinct_catalog_refunded_addresses,
    COUNT(DISTINCT ca_returning.ca_address_id)     AS distinct_catalog_returning_addresses,
    COUNT(DISTINCT ca_wr_refunded.ca_address_id)   AS distinct_web_refunded_addresses,
    COUNT(DISTINCT ca_wr_returning.ca_address_id)  AS distinct_web_returning_addresses
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_date,
    d.d_day_name,
    s.s_store_name,
    s.s_state
ORDER BY total_catalog_net_loss DESC
LIMIT 100
