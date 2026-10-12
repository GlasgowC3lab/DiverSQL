WITH returning_agg AS (
  SELECT
    hd_ret.hd_income_band_sk,
    hd_ret.hd_vehicle_count,
    COUNT(*) AS cnt_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items
  FROM web_returns wr
  JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  WHERE wr.wr_returning_addr_sk IN (904057, 4798793)
    AND hd_ret.hd_buy_potential = '1001-5000'
  GROUP BY hd_ret.hd_income_band_sk, hd_ret.hd_vehicle_count
  HAVING COUNT(*) > 2
),
refunded_agg AS (
  SELECT
    hd_ref.hd_income_band_sk,
    hd_ref.hd_vehicle_count,
    SUM(wr.wr_net_loss) AS total_net_loss_refunded,
    AVG(wr.wr_return_amt) AS avg_return_amt_refunded,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_refunded
  FROM web_returns wr
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  WHERE hd_ref.hd_income_band_sk IN (3,4,5)
    AND wr.wr_return_quantity > 0
  GROUP BY hd_ref.hd_income_band_sk, hd_ref.hd_vehicle_count
  HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
  r.hd_income_band_sk,
  r.hd_vehicle_count,
  r.cnt_returns,
  r.total_net_loss,
  r.avg_return_amt,
  r.distinct_items,
  COALESCE(f.total_net_loss_refunded, 0) AS total_net_loss_refunded,
  COALESCE(f.avg_return_amt_refunded, 0) AS avg_return_amt_refunded,
  COALESCE(f.distinct_items_refunded, 0) AS distinct_items_refunded,
  CASE WHEN r.total_net_loss = 0 THEN NULL
       ELSE COALESCE(f.total_net_loss_refunded,0) / r.total_net_loss END AS loss_ratio_refunded_to_returning
FROM returning_agg r
LEFT JOIN refunded_agg f
  ON r.hd_income_band_sk = f.hd_income_band_sk
  AND r.hd_vehicle_count = f.hd_vehicle_count
ORDER BY r.total_net_loss DESC
LIMIT 100
