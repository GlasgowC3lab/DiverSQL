WITH agg_base AS (
    SELECT
        ca.ca_state AS state,
        r.r_reason_desc AS reason,
        cd.cd_gender AS gender,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(cr.cr_return_quantity) AS total_quantity
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_warehouse_sk IN (7, 14, 9)
      AND cr.cr_fee > 20.0
      AND cr.cr_return_ship_cost > 100.0
    GROUP BY ca.ca_state, r.r_reason_desc, cd.cd_gender
    HAVING COUNT(*) >= 5
),
agg AS (
    SELECT
        state,
        gender,
        reason,
        return_cnt,
        total_net_loss,
        avg_fee,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY state, gender ORDER BY total_net_loss DESC) AS rn
    FROM agg_base
)
SELECT
    state,
    gender,
    reason,
    return_cnt,
    total_net_loss,
    avg_fee,
    total_quantity
FROM agg
WHERE rn <= 3
ORDER BY state, gender, total_net_loss DESC
