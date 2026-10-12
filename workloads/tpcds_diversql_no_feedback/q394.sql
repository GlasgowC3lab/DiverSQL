WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        ca.ca_state,
        ca.ca_country,
        ca.ca_location_type
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 100
      AND sr.sr_refunded_cash < 500
      AND ca.ca_state IN ('CA', 'TX')
      AND ca.ca_location_type = 'apartment'
),
ranked AS (
    SELECT
        sr_returned_date_sk,
        sr_customer_sk,
        sr_return_amt,
        ca_state,
        ca_location_type,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY sr_return_amt DESC) AS rn,
        RANK() OVER (PARTITION BY ca_state ORDER BY sr_return_amt DESC) AS rnk
    FROM filtered_returns
),
exists_filtered AS (
    SELECT *
    FROM ranked r
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = r.sr_customer_sk
          AND sr2.sr_return_quantity > 1
    )
),
keys_a AS (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_return_amt >= 200
),
keys_b AS (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_refunded_cash > 50
),
keys_c AS (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_return_ship_cost < 100
),
final_keys AS (
    SELECT sr_customer_sk FROM keys_a
    INTERSECT
    SELECT sr_customer_sk FROM keys_b
    EXCEPT
    SELECT sr_customer_sk FROM keys_c
)
SELECT
    ef.sr_customer_sk,
    ef.sr_return_amt,
    ef.ca_state,
    ef.ca_location_type,
    ef.rn,
    ef.rnk
FROM exists_filtered ef
JOIN final_keys fk
    ON ef.sr_customer_sk = fk.sr_customer_sk
ORDER BY ef.rnk, ef.sr_return_amt DESC
LIMIT 100
