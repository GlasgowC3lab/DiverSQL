WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),

-- Aggregate the sampled returns (fact) by the returning address (dimension)
returns_agg AS (
    SELECT
        cr_returning_addr_sk AS returning_addr_sk,
        SUM(cr_return_amount)        AS sum_return_amount,
        SUM(cr_fee)                  AS sum_fee,
        COUNT(*)                     AS cnt_returns,
        AVG(cr_net_loss)             AS avg_net_loss
    FROM sampled_returns
    WHERE cr_fee > 30
      AND cr_return_quantity >= 1
      AND cr_return_amt_inc_tax > 500
    GROUP BY cr_returning_addr_sk
),

-- Right outer join so every address row is kept even if there is no matching return
right_joined AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        ra.sum_return_amount,
        ra.sum_fee,
        ra.cnt_returns,
        ra.avg_net_loss,
        ra.returning_addr_sk
    FROM returns_agg ra
    RIGHT OUTER JOIN customer_address ca
        ON ra.returning_addr_sk = ca.ca_address_sk
),

-- Anti‑join: keep only addresses for which no refunded‑address record exists
addresses_without_refund AS (
    SELECT ca.*
    FROM customer_address ca
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_addr_sk = ca.ca_address_sk
    )
),

-- Full outer join the right‑joined data with the anti‑join set
full_joined AS (
    SELECT
        COALESCE(rj.ca_address_sk, awf.ca_address_sk) AS ca_address_sk,
        COALESCE(rj.ca_city, awf.ca_city)           AS ca_city,
        COALESCE(rj.ca_state, awf.ca_state)         AS ca_state,
        COALESCE(rj.ca_location_type, awf.ca_location_type) AS ca_location_type,
        COALESCE(rj.ca_gmt_offset, awf.ca_gmt_offset)       AS ca_gmt_offset,
        rj.sum_return_amount,
        rj.sum_fee,
        rj.cnt_returns,
        rj.avg_net_loss,
        rj.returning_addr_sk
    FROM right_joined rj
    FULL OUTER JOIN addresses_without_refund awf
        ON rj.returning_addr_sk = awf.ca_address_sk
),

-- Set of address keys that appear in any return (any side)
returns_addr_set AS (
    SELECT DISTINCT cr.cr_returning_addr_sk AS addr_sk
    FROM catalog_returns cr
),

-- All address keys
all_addr_set AS (
    SELECT ca_address_sk AS addr_sk
    FROM customer_address
),

-- Addresses that never appear in a return (EXCEPT)
addr_not_in_returns AS (
    SELECT addr_sk
    FROM all_addr_set
    EXCEPT
    SELECT addr_sk FROM returns_addr_set
),

-- Union of the full‑joined data with the addresses that never had returns (deduped via UNION)
unioned AS (
    SELECT
        ca_address_sk   AS address_sk,
        ca_city,
        ca_state,
        ca_location_type,
        ca_gmt_offset,
        sum_return_amount,
        sum_fee,
        cnt_returns,
        avg_net_loss
    FROM full_joined
    UNION
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        NULL,
        NULL,
        NULL,
        NULL
    FROM customer_address ca
    JOIN addr_not_in_returns anr ON ca.ca_address_sk = anr.addr_sk
)

SELECT
    address_sk,
    ca_city,
    ca_state,
    ca_location_type,
    ca_gmt_offset,
    sum_return_amount,
    sum_fee,
    cnt_returns,
    avg_net_loss
FROM unioned
WHERE ca_gmt_offset = -5.00
  AND ca_location_type = 'condo'
  AND (sum_return_amount IS NOT NULL AND sum_return_amount > 1000)
ORDER BY sum_return_amount DESC NULLS LAST
LIMIT 100
