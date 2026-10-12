/*
  Goal: Identify store return records enriched with customer address information, applying complex string filters, a full outer join, an anti‑semi‑join (NOT IN), and an intersected key set to focus on a nuanced subset of addresses and returns. The result is limited to the first 100 rows.
*/
WITH
  addr_filtered AS (
    SELECT
      ca_address_sk,
      ca_city,
      ca_state,
      ca_street_type,
      ca_suite_number,
      ca_gmt_offset,
      CONCAT(ca_city, ', ', ca_state) AS city_state,
      CASE
        WHEN regexp_like(ca_suite_number, '^Suite [A-Z]$') THEN 'AlphaSuite'
        ELSE 'OtherSuite'
      END AS suite_category
    FROM tpcds.customer_address
    WHERE ca_street_type LIKE 'Blvd%'
       OR ca_street_type LIKE '%Lane'
  ),

  returns_filtered AS (
    SELECT
      sr_addr_sk,
      sr_return_amt,
      sr_return_tax,
      sr_refunded_cash,
      sr_return_quantity,
      sr_net_loss
    FROM tpcds.store_returns
    WHERE sr_return_amt > 100
  ),

  full_join AS (
    SELECT
      a.ca_address_sk,
      a.city_state,
      a.suite_category,
      r.sr_return_amt,
      r.sr_return_tax,
      r.sr_refunded_cash,
      r.sr_return_quantity,
      r.sr_net_loss
    FROM addr_filtered a
    FULL OUTER JOIN returns_filtered r
      ON a.ca_address_sk = r.sr_addr_sk
  ),

  intersect_keys AS (
    SELECT ca_address_sk AS key_sk FROM tpcds.customer_address WHERE ca_state LIKE 'A%'
    INTERSECT
    SELECT sr_addr_sk AS key_sk FROM tpcds.store_returns WHERE sr_return_tax > 20
  )
SELECT
  fj.ca_address_sk,
  fj.city_state,
  fj.suite_category,
  fj.sr_return_amt,
  fj.sr_return_tax,
  fj.sr_refunded_cash,
  fj.sr_return_quantity,
  fj.sr_net_loss
FROM full_join fj
WHERE fj.ca_address_sk NOT IN (
        SELECT ca_address_sk FROM tpcds.customer_address WHERE ca_gmt_offset = -5.00
      )
  AND fj.ca_address_sk IN (SELECT key_sk FROM intersect_keys)
LIMIT 100
