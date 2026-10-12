WITH reason_state AS (
    SELECT
        cr.cr_reason_sk AS reason_sk,
        ca.ca_state AS state,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS qty,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        sr.sr_reason_sk AS reason_sk,
        ca.ca_state AS state,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS qty,
        'store' AS source
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
 state_reason_rank AS (
    SELECT
        rs.state,
        rs.reason_sk,
        SUM(rs.net_loss) AS total_net_loss,
        SUM(rs.qty) AS total_qty,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY rs.state ORDER BY SUM(rs.net_loss) DESC) AS rn
    FROM reason_state rs
    GROUP BY rs.state, rs.reason_sk
)
SELECT
    srr.state,
    srr.reason_sk,
    srr.total_net_loss,
    srr.total_qty,
    srr.return_cnt,
    CASE
        WHEN srr.total_net_loss > 10000 THEN 'Severe'
        WHEN srr.total_net_loss > 5000 THEN 'Moderate'
        ELSE 'Mild'
    END AS severity_level
FROM state_reason_rank srr
WHERE srr.rn <= 3
ORDER BY srr.state, srr.rn
