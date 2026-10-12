-- Goal: Calculate average net loss per state for addresses with significant losses, after joining store returns with customer addresses using a full outer join and multi‑level aggregation.
WITH joined AS (
    SELECT
        sr.sr_addr_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_refunded_cash,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_street_type,
        ca.ca_suite_number
    FROM store_returns sr
    FULL OUTER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        sr.sr_net_loss > 100                -- filter 1: sizable net loss
        AND sr.sr_return_quantity >= 1       -- filter 2: at least one item returned
        AND ca.ca_country = 'United States' -- filter 3: only US addresses
),
agg_address AS (
    SELECT
        COALESCE(ca_address_sk, sr_addr_sk) AS address_key,
        ca_city,
        ca_state,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY
        COALESCE(ca_address_sk, sr_addr_sk),
        ca_city,
        ca_state
),
agg_state AS (
    SELECT
        ca_state,
        AVG(total_net_loss) AS avg_net_loss,
        SUM(total_refunded_cash) AS sum_refunded_cash,
        SUM(return_cnt) AS total_returns
    FROM agg_address
    GROUP BY ca_state
    HAVING AVG(total_net_loss) > 150
)
SELECT
    ca_state,
    avg_net_loss,
    sum_refunded_cash,
    total_returns,
    ROW_NUMBER() OVER (ORDER BY avg_net_loss DESC) AS rn
FROM agg_state
ORDER BY avg_net_loss DESC
LIMIT 100
