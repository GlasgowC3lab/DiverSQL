SELECT
    hd.hd_income_band_sk,
    i.i_brand,
    r.r_reason_desc,
    sub.total_return_amount,
    sub.return_count
FROM (
    SELECT
        sr.sr_hdemo_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 70
    GROUP BY sr.sr_hdemo_sk, sr.sr_item_sk, sr.sr_reason_sk
    HAVING SUM(sr.sr_return_amt) > 217.28
) sub
JOIN household_demographics hd ON sub.sr_hdemo_sk = hd.hd_demo_sk
JOIN item i ON sub.sr_item_sk = i.i_item_sk
JOIN reason r ON sub.sr_reason_sk = r.r_reason_sk
WHERE i.i_current_price < 29.35
  AND hd.hd_dep_count = 5
