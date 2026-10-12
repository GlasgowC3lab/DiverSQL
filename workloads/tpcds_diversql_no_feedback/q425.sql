WITH
  agg_sales AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_promo_sk,
      SUM(cs_net_profit) AS total_sales_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_call_center_sk, cs_promo_sk
  ),
  agg_returns AS (
    SELECT
      sr_item_sk AS cs_item_sk,
      sr_returned_date_sk AS cs_sold_date_sk,
      CAST(NULL AS integer) AS cs_call_center_sk,
      CAST(NULL AS integer) AS cs_promo_sk,
      SUM(sr_net_loss) AS total_store_loss,
      COUNT(*) AS ret_cnt
    FROM store_returns
    GROUP BY sr_item_sk, sr_returned_date_sk
  ),
  union_data AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_promo_sk,
      total_sales_profit AS profit,
      0.0 AS loss,
      sales_cnt,
      0 AS ret_cnt
    FROM agg_sales
    UNION
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_promo_sk,
      0.0 AS profit,
      total_store_loss AS loss,
      0 AS sales_cnt,
      ret_cnt
    FROM agg_returns
  )
SELECT
  i.i_category,
  i.i_brand,
  cc.cc_state,
  p.p_promo_name,
  d.d_year,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(u.profit) AS total_profit,
  SUM(u.loss)   AS total_loss,
  SUM(u.profit) - SUM(u.loss) AS total_contribution,
  COUNT(*) AS transaction_count
FROM union_data u
JOIN item i
  ON i.i_item_sk = u.cs_item_sk
JOIN date_dim d
  ON d.d_date_sk = u.cs_sold_date_sk
LEFT JOIN call_center cc
  ON cc.cc_call_center_sk = u.cs_call_center_sk
LEFT JOIN promotion p
  ON p.p_promo_sk = u.cs_promo_sk
LEFT JOIN date_dim d_open
  ON d_open.d_date_sk = cc.cc_open_date_sk
LEFT JOIN date_dim d_close
  ON d_close.d_date_sk = cc.cc_closed_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = u.cs_item_sk
 AND cr.cr_returned_date_sk = u.cs_sold_date_sk
LEFT JOIN reason r
  ON r.r_reason_sk = cr.cr_reason_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
LEFT JOIN customer_demographics cd
  ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
LEFT JOIN household_demographics hd
  ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
LEFT JOIN income_band ib
  ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = u.cs_item_sk
 AND wr.wr_returned_date_sk = u.cs_sold_date_sk
LEFT JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
  i.i_category,
  i.i_brand,
  cc.cc_state,
  p.p_promo_name,
  d.d_year,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound
HAVING (SUM(u.profit) - SUM(u.loss)) > 10000
ORDER BY total_contribution DESC
LIMIT 100
