WITH store_ret AS (
    SELECT ca.ca_address_id,
           ca.ca_city,
           ca.ca_state,
           SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_net_loss > 100
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
),
catalog_ret AS (
    SELECT ca.ca_address_id,
           ca.ca_city,
           ca.ca_state,
           SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_net_loss > 100
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT *
FROM store_ret
EXCEPT
SELECT *
FROM catalog_ret
ORDER BY total_loss DESC
LIMIT 100
