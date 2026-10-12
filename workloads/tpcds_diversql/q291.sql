WITH agg_returns AS (
    SELECT
        sr_hdemo_sk,
        sr_reason_sk,
        sr_returned_date_sk,
        sr_addr_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY sr_hdemo_sk, sr_reason_sk, sr_returned_date_sk, sr_addr_sk
)
SELECT
    cc.cc_name,
    cc.cc_state,
    d.d_year,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    AVG(ar.total_net_loss) AS avg_net_loss,
    SUM(ar.return_cnt) AS total_returns
FROM agg_returns ar
JOIN date_dim d ON ar.sr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN household_demographics hd ON ar.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r ON ar.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON ar.sr_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2002
  AND cc.cc_state = 'CA'
  AND ib.ib_upper_bound >= 50000
  AND r.r_reason_desc LIKE '%warranty%'
  AND ca.ca_gmt_offset BETWEEN -5 AND 5
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_addr_sk = ar.sr_addr_sk
          AND sr2.sr_net_loss > 0
    )
  AND ar.sr_addr_sk IN (
        SELECT sr_addr_sk FROM store_returns
        EXCEPT
        SELECT sr_addr_sk FROM store_returns WHERE sr_return_quantity = 0
    )
GROUP BY cc.cc_name, cc.cc_state, d.d_year, r.r_reason_desc, hd.hd_buy_potential, ib.ib_lower_bound
ORDER BY avg_net_loss DESC
LIMIT 100
