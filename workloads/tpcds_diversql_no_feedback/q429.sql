/**
 * Goal: Compute the total return amount, quantity and count of returns for Express air shipments
 *       that cost more than $100 to ship, limited to specific counties. The results are aggregated
 *       using a CUBE on ship mode type and county to produce subtotals and grand totals, and each
 *       row is ranked within its ship‑mode type by the total return amount. A CASE expression flags
 *       high‑value groups.
 */
WITH agg_returns AS (
    SELECT
        cr_ship_mode_sk,
        cr_refunded_addr_sk,
        SUM(cr_return_amount)            AS total_return_amount,
        SUM(cr_return_quantity)          AS total_return_quantity,
        COUNT(*)                         AS cnt_returns,
        SUM(cr_return_ship_cost)         AS total_ship_cost
    FROM catalog_returns
    WHERE cr_return_ship_cost > 100.00
    GROUP BY cr_ship_mode_sk, cr_refunded_addr_sk
),
cube_agg AS (
    SELECT
        sm.sm_type,
        ca.ca_county,
        SUM(agg.total_return_amount)   AS sum_return_amount,
        SUM(agg.total_return_quantity) AS sum_return_quantity,
        SUM(agg.cnt_returns)           AS total_returns
    FROM agg_returns agg
    JOIN ship_mode sm
        ON agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON agg.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND sm.sm_code = 'AIR'
      AND ca.ca_county IN ('Perry County', 'Madison County')
    GROUP BY CUBE(sm.sm_type, ca.ca_county)
)
SELECT
    sm_type,
    ca_county,
    sum_return_amount,
    sum_return_quantity,
    total_returns,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY sum_return_amount DESC) AS rn_by_amount,
    CASE WHEN sum_return_amount > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category
FROM cube_agg
ORDER BY sum_return_amount DESC
LIMIT 100
