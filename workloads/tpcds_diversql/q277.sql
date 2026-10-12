WITH agg_returns AS (
    SELECT
        wr_refunded_hdemo_sk AS hd_demo_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_qty
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_return_tax > 5
      AND wr_return_quantity >= 1
      AND wr_returned_time_sk BETWEEN 30000 AND 80000
      AND wr_fee < 50
      AND wr_reversed_charge <> 0
    GROUP BY wr_refunded_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_income_band_sk,
    ar.return_cnt,
    ar.total_return_amt,
    ar.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY ar.total_net_loss DESC) AS rn_by_buy_potential,
    CASE
        WHEN ar.total_net_loss > 1000 THEN 'HIGH'
        WHEN ar.total_net_loss > 500  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM agg_returns ar
JOIN household_demographics hd
  ON ar.hd_demo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count IN (0, 4, 5)
  AND hd.hd_buy_potential IN ('0-500', '>10000')
  AND hd.hd_income_band_sk BETWEEN 5 AND 20
  AND hd.hd_income_band_sk IN (
        SELECT DISTINCT hd_income_band_sk
        FROM household_demographics
        WHERE hd_dep_count >= 4
    )
  AND ar.return_cnt > 10
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = ar.hd_demo_sk
          AND wr2.wr_return_amt > 200
    )
ORDER BY ar.total_net_loss DESC
LIMIT 100
