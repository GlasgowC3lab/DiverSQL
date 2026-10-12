WITH filtered_returns AS (
  SELECT
    cr.cr_item_sk,
    cr.cr_warehouse_sk,
    cr.cr_return_quantity,
    cr.cr_return_amt_inc_tax,
    cr.cr_net_loss,
    cr.cr_refunded_hdemo_sk,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    hd_ret.hd_income_band_sk AS returning_income_band
  FROM catalog_returns cr
  JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  WHERE cr.cr_warehouse_sk = 14
    AND cr.cr_return_quantity >= 20
    AND hd_ref.hd_vehicle_count >= 2
),
aggregated AS (
  SELECT
    i.i_category,
    i.i_brand,
    p.p_channel_tv,
    fr.refunded_income_band,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    COUNT(*) AS return_cnt
  FROM filtered_returns fr
  JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
  JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
  WHERE p.p_channel_tv = 'Y'
    AND p.p_cost > 500
  GROUP BY i.i_category, i.i_brand, p.p_channel_tv, fr.refunded_income_band
)
SELECT
  a.i_category,
  a.i_brand,
  a.p_channel_tv,
  a.refunded_income_band,
  a.total_net_loss,
  a.avg_return_amt_inc_tax,
  a.return_cnt,
  RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 10
