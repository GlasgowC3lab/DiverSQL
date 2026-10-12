/*
  Goal: Compute total net loss, number of returns, and average store credit for each combination of state, location type, and street type that meets several address and return criteria.  Bucket the results by total tax amount, then cross‑join the aggregates with a small set of quarterly periods to see the same metrics per period.
*/
WITH base AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_street_type,
        sr.sr_store_credit,
        sr.sr_return_tax,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')                -- predicate 1
      AND ca.ca_location_type = 'single family'                     -- predicate 2
      AND ca.ca_street_type IN ('Ave', 'Road', 'Dr.')               -- predicate 3
      AND sr.sr_return_tax > 0                                      -- predicate 4
      AND sr.sr_store_credit >= 1                                    -- predicate 5
),
agg AS (
    SELECT
        ca_state,
        ca_location_type,
        ca_street_type,
        SUM(sr_net_loss)                     AS total_loss,
        COUNT(*)                             AS return_cnt,
        AVG(sr_store_credit)                 AS avg_credit,
        SUM(sr_return_tax)                   AS total_tax,
        CASE WHEN SUM(sr_return_tax) > 200 THEN 'high_tax' ELSE 'low_tax' END AS tax_bucket
    FROM base
    GROUP BY ca_state, ca_location_type, ca_street_type
),
periods AS (
    SELECT * FROM (VALUES
        ('2023-Q1'),
        ('2023-Q2')
    ) AS t(period)
),
final AS (
    SELECT
        p.period,
        a.ca_state,
        a.ca_location_type,
        a.tax_bucket,
        a.total_loss,
        a.return_cnt,
        a.avg_credit
    FROM agg a
    CROSS JOIN periods p
    WHERE a.avg_credit > 5
)
SELECT
    period,
    ca_state,
    ca_location_type,
    tax_bucket,
    total_loss,
    return_cnt,
    avg_credit
FROM final
ORDER BY total_loss DESC
LIMIT 100
