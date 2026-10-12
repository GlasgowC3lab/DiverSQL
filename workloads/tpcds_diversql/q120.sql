WITH cr_sm AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier IN ('UPS', 'USPS')
      AND sm.sm_contract LIKE 'A%'
)
SELECT
    cr_sm.cr_returned_date_sk,
    i.i_item_id,
    i.i_brand,
    i.i_current_price,
    r.r_reason_desc,
    cr_sm.sm_carrier,
    cr_sm.cr_return_amount,
    cr_sm.cr_net_loss,
    sr.sr_return_tax,
    (
        SELECT SUM(s2.sr_return_amt)
        FROM store_returns s2
        WHERE s2.sr_item_sk = i.i_item_sk
    ) AS total_store_return_amt_for_item,
    word,
    RANK() OVER (PARTITION BY cr_sm.sm_carrier ORDER BY cr_sm.cr_return_amount DESC) AS carrier_return_amount_rank
FROM cr_sm
JOIN item i
    ON cr_sm.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr_sm.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_reason_sk = r.r_reason_sk
CROSS JOIN UNNEST(SPLIT(i.i_item_desc, ' ')) AS t(word)
WHERE i.i_current_price BETWEEN 10 AND 100
  AND cr_sm.cr_return_amount > 0
  AND sr.sr_return_tax > 5
  AND r.r_reason_desc LIKE '%color%'
  AND i.i_brand = 'BrandX'
  AND cr_sm.cr_returned_date_sk BETWEEN 2450000 AND 2450100
ORDER BY carrier_return_amount_rank
LIMIT 100
