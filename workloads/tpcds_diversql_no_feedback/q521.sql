WITH sr_agg AS (
    SELECT
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
      AND sr.sr_fee BETWEEN 20 AND 100
      AND sr.sr_return_tax > 30
      AND sr.sr_return_ship_cost < 500
    GROUP BY sr.sr_addr_sk, sr.sr_reason_sk
),
ws_f AS (
    SELECT
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_quantity,
        ws.ws_ext_wholesale_cost
    FROM web_sales ws
    WHERE ws.ws_quantity > 30
      AND ws.ws_ext_wholesale_cost > (
          SELECT AVG(ws2.ws_ext_wholesale_cost)
          FROM web_sales ws2
      )
)
SELECT
    r.r_reason_desc,
    ca.ca_county,
    ca.ca_location_type,
    sr_agg.total_return_amt,
    sr_agg.total_fee,
    sr_agg.return_cnt,
    ws_f.ws_quantity,
    ws_f.ws_ext_wholesale_cost,
    LAG(sr_agg.total_return_amt) OVER (PARTITION BY r.r_reason_sk ORDER BY sr_agg.total_return_amt DESC) AS lag_return_amt
FROM sr_agg
JOIN reason r
    ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca
    ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN ws_f
    ON ws_f.ws_bill_addr_sk = ca.ca_address_sk
   AND ws_f.ws_ship_addr_sk = ca.ca_address_sk
WHERE ca.ca_county IN ('Perry County', 'Williams County')
  AND ca.ca_location_type = 'condo'
  AND sr_agg.total_return_amt > 1000
  AND sr_agg.total_fee < 500
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_addr_sk = ca.ca_address_sk
          AND sr2.sr_return_tax > 75
    )
ORDER BY sr_agg.total_return_amt DESC
LIMIT 100
