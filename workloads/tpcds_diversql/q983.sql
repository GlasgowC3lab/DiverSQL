WITH
  store_full AS (
    SELECT
      ss.ss_sold_date_sk,
      td.t_shift,
      td.t_meal_time,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      hd.hd_income_band_sk,
      p.p_promo_name,
      r.r_reason_desc,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM
      store_sales ss
      JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
      LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
      td.t_shift = 'first'
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 3000
      AND hd.hd_income_band_sk BETWEEN 2 AND 5
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND ss.ss_net_profit > 0
  ),

  web_full AS (
    SELECT
      ws.ws_sold_date_sk,
      td.t_shift,
      td.t_meal_time,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      hd.hd_income_band_sk,
      p.p_promo_name,
      r.r_reason_desc,
      ws.ws_net_profit,
      wr.wr_return_quantity,
      wr.wr_net_loss
    FROM
      web_sales ws
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
      LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
      td.t_shift = 'first'
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 3000
      AND hd.hd_income_band_sk BETWEEN 2 AND 5
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND ws.ws_net_profit > 0
  ),

  catalog_full AS (
    SELECT
      cs.cs_sold_date_sk,
      td.t_shift,
      td.t_meal_time,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      hd.hd_income_band_sk,
      p.p_promo_name,
      r.r_reason_desc,
      cs.cs_net_paid_inc_tax,
      cr.cr_return_quantity,
      cr.cr_net_loss
    FROM
      catalog_sales cs TABLESAMPLE BERNOULLI (10)
      JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
      JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
      LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
      td.t_shift = 'first'
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 3000
      AND hd.hd_income_band_sk BETWEEN 2 AND 5
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND cs.cs_net_paid_inc_tax > 0
  )

SELECT
  COALESCE(sf.t_shift, wf.t_shift)                AS shift,
  COALESCE(sf.t_meal_time, wf.t_meal_time)        AS meal_time,
  COALESCE(sf.cd_gender, wf.cd_gender)            AS gender,
  COALESCE(sf.hd_income_band_sk, wf.hd_income_band_sk) AS income_band,
  COALESCE(sf.p_promo_name, wf.p_promo_name)      AS promo_name,
  COALESCE(sf.r_reason_desc, wf.r_reason_desc)    AS reason_desc,
  COALESCE(sf.ss_net_profit, 0) + COALESCE(wf.ws_net_profit, 0) AS total_net_profit,
  COALESCE(sf.sr_return_quantity, 0) + COALESCE(wf.wr_return_quantity, 0) AS total_return_qty,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(sf.t_shift, wf.t_shift) ORDER BY (COALESCE(sf.ss_net_profit, 0) + COALESCE(wf.ws_net_profit, 0)) DESC) AS rn
FROM
  store_full sf
  FULL OUTER JOIN web_full wf
    ON sf.t_shift = wf.t_shift
   AND sf.t_meal_time = wf.t_meal_time
   AND sf.cd_gender = wf.cd_gender
WHERE
  EXISTS (
    SELECT 1
    FROM reason r_sub
    WHERE r_sub.r_reason_desc = COALESCE(sf.r_reason_desc, wf.r_reason_desc)
      AND r_sub.r_reason_desc LIKE '%damage%'
  )

UNION DISTINCT

SELECT
  cf.t_shift                AS shift,
  cf.t_meal_time            AS meal_time,
  cf.cd_gender              AS gender,
  cf.hd_income_band_sk      AS income_band,
  cf.p_promo_name           AS promo_name,
  cf.r_reason_desc          AS reason_desc,
  cf.cs_net_paid_inc_tax    AS total_net_profit,
  cf.cr_return_quantity     AS total_return_qty,
  ROW_NUMBER() OVER (PARTITION BY cf.t_shift ORDER BY cf.cs_net_paid_inc_tax DESC) AS rn
FROM
  catalog_full cf
WHERE
  EXISTS (
    SELECT 1
    FROM reason r_sub
    WHERE r_sub.r_reason_desc = cf.r_reason_desc
      AND r_sub.r_reason_desc LIKE '%damage%'
  )

ORDER BY
  total_net_profit DESC
LIMIT 100
