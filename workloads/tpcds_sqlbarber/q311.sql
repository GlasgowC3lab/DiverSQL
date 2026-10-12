SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_return_amt * (1 + s.s_tax_percentage / 100) AS total_with_tax,
    CASE
        WHEN sr.sr_return_quantity > 4 THEN 'Bulk Return'
        WHEN sr.sr_return_quantity = 17 THEN 'No Return'
        ELSE 'Standard Return'
    END AS return_type,
    CONCAT(s.s_city, ', ', s.s_state) AS city_state,
    (sr.sr_return_amt - sr.sr_return_tax) AS net_amount_excl_tax,
    CASE
        WHEN s.s_gmt_offset < 0 THEN s.s_gmt_offset * -1
        ELSE s.s_gmt_offset
    END AS gmt_offset_abs,
    (sr.sr_return_quantity * sr.sr_return_amt) AS total_return_value
FROM store_returns sr
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'FL'
  AND sr.sr_return_quantity > 41
