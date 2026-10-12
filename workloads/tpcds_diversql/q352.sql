WITH ship_modes_without_high_tax AS (
    SELECT sm_ship_mode_sk
    FROM ship_mode
    EXCEPT
    SELECT DISTINCT cr_ship_mode_sk
    FROM catalog_returns
    WHERE cr_return_tax > 200
),
base AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        td.t_am_pm,
        td.t_second,
        ca.ca_state,
        la.addr_cnt
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(DISTINCT cr2.cr_refunded_addr_sk) AS addr_cnt
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
    ) la ON TRUE
    LEFT JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        sm.sm_contract = 'OrDuVy2H'
        AND td.t_am_pm = 'PM'
        AND cr.cr_return_quantity > 5
        AND sm.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_modes_without_high_tax)
),
agg1 AS (
    SELECT
        sm_ship_mode_id,
        sm_contract,
        t_am_pm,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        COUNT(*) AS cnt_returns,
        AVG(addr_cnt) AS avg_addr_cnt
    FROM base
    GROUP BY sm_ship_mode_id, sm_contract, t_am_pm
),
final AS (
    SELECT
        sm_ship_mode_id,
        AVG(total_return_amount) AS avg_total_return_amount,
        SUM(total_return_tax) AS sum_total_return_tax,
        SUM(cnt_returns) AS sum_cnt_returns,
        AVG(avg_addr_cnt) AS overall_avg_addr_cnt
    FROM agg1
    GROUP BY sm_ship_mode_id
    HAVING SUM(total_return_tax) > 100
)
SELECT
    sm_ship_mode_id,
    avg_total_return_amount,
    sum_total_return_tax,
    sum_cnt_returns,
    overall_avg_addr_cnt
FROM final
ORDER BY avg_total_return_amount DESC
LIMIT 100
