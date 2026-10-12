WITH
  pre_cat AS (
    SELECT
      cs_call_center_sk,
      cs_sold_date_sk,
      cs_ship_mode_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_bill_addr_sk,
      cs_bill_cdemo_sk,
      SUM(cs_net_paid) AS sum_net_paid,
      COUNT(*) AS cnt_orders
    FROM catalog_sales
    WHERE cs_quantity > 5
    GROUP BY cs_call_center_sk, cs_sold_date_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_promo_sk, cs_bill_addr_sk, cs_bill_cdemo_sk
  ),
  pre_web AS (
    SELECT
      ws_sold_date_sk,
      ws_ship_mode_sk,
      ws_warehouse_sk,
      ws_promo_sk,
      ws_bill_addr_sk,
      ws_bill_cdemo_sk,
      SUM(ws_net_paid) AS sum_net_paid,
      COUNT(*) AS cnt_orders
    FROM web_sales
    WHERE ws_quantity > 5
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_promo_sk, ws_bill_addr_sk, ws_bill_cdemo_sk
  ),
  store_full AS (
    SELECT
      s.s_store_sk,
      s.s_state,
      s.s_city,
      s.s_closed_date_sk,
      sr.sr_store_sk AS sr_store_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
  )
SELECT
  result.d_year,
  result.state,
  result.total_net_paid,
  result.total_orders,
  result.profit_category
FROM (
  SELECT
    d.d_year AS d_year,
    cc.cc_state AS state,
    SUM(pc.sum_net_paid) AS total_net_paid,
    SUM(pc.cnt_orders) AS total_orders,
    CASE WHEN SUM(pc.sum_net_paid) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
  FROM pre_cat pc
  JOIN call_center cc ON pc.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON pc.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p ON pc.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON pc.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON pc.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON pc.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON pc.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
  GROUP BY d.d_year, cc.cc_state

  UNION DISTINCT

  SELECT
    d.d_year AS d_year,
    sf.s_state AS state,
    SUM(pw.sum_net_paid) AS total_net_paid,
    SUM(pw.cnt_orders) AS total_orders,
    CASE WHEN SUM(pw.sum_net_paid) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
  FROM pre_web pw
  JOIN date_dim d ON pw.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON pw.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON pw.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON pw.ws_warehouse_sk = w.w_warehouse_sk
  JOIN store_full sf ON sf.s_closed_date_sk = d.d_date_sk
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS addr_in_state
    FROM customer_address ca2
    WHERE ca2.ca_state = sf.s_state
  ) la ON TRUE
  WHERE d.d_year = 2001
    AND p.p_channel_radio = 'N'
    AND pw.sum_net_paid > 1000
  GROUP BY d.d_year, sf.s_state
) result
ORDER BY result.total_net_paid DESC
OFFSET 0
LIMIT 100
