SELECT
    cc.cc_division,
    cc.cc_city,
    p.p_channel_tv,
    i.i_category,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    SUM(coalesce(cr.cr_net_loss, 0) + coalesce(sr.sr_net_loss, 0)) AS total_net_loss,
    SUM(coalesce(cr.cr_return_amount, 0) + coalesce(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(coalesce(cr.cr_fee, 0) + coalesce(sr.sr_fee, 0)) AS total_fees,
    AVG(p.p_cost) AS avg_promo_cost,
    ROUND(
        (SUM(coalesce(cr.cr_return_amount, 0) + coalesce(sr.sr_return_amt, 0))
         - SUM(coalesce(cr.cr_net_loss, 0) + coalesce(sr.sr_net_loss, 0)))
        / NULLIF(SUM(coalesce(cr.cr_return_amount, 0) + coalesce(sr.sr_return_amt, 0)), 0) * 100,
        2
    ) AS profit_margin_pct
FROM item i
LEFT JOIN catalog_returns cr
    ON i.i_item_sk = cr.cr_item_sk
    AND cr.cr_returned_date_sk >= 2451545
LEFT JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
    AND sr.sr_returned_date_sk >= 2451545
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
WHERE cc.cc_division IN (1, 2, 3)
  AND cc.cc_hours = '8AM-4PM'
  AND p.p_discount_active = 'Y'
  AND i.i_category IS NOT NULL
GROUP BY
    cc.cc_division,
    cc.cc_city,
    p.p_channel_tv,
    i.i_category
HAVING SUM(coalesce(cr.cr_net_loss, 0) + coalesce(sr.sr_net_loss, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 100
