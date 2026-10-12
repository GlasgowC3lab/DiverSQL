WITH returns_agg AS (
    SELECT
        sr_customer_sk,
        sr_hdemo_sk,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_return_amt) AS avg_return_amt,
        SUM(sr_return_quantity) AS total_qty,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_amt > 100.00
      AND sr_return_quantity >= 2
    GROUP BY sr_customer_sk, sr_hdemo_sk
    HAVING SUM(sr_net_loss) > 200.00
)
SELECT
    c.c_customer_sk,
    c.c_last_name,
    c.c_email_address,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ra.total_net_loss,
    ra.avg_return_amt,
    ra.total_qty,
    ra.return_cnt
FROM returns_agg ra
JOIN customer c
  ON ra.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ra.sr_hdemo_sk = hd.hd_demo_sk
  AND c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1975
  AND ib.ib_upper_bound <= 150000
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_last_review_date > 2452400
ORDER BY ra.total_net_loss DESC
LIMIT 100
