WITH
  store_agg AS (
    SELECT
      p.p_promo_name      AS promo_name,
      s.s_state           AS region_state,
      ib.ib_lower_bound   AS income_lower,
      SUM(ss.ss_net_paid)    AS total_net_paid,
      SUM(ss.ss_net_profit)  AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM
      store_sales ss TABLESAMPLE BERNOULLI (10)
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY
      p.p_promo_name,
      s.s_state,
      ib.ib_lower_bound
  ),
  catalog_agg AS (
    SELECT
      p.p_promo_name      AS promo_name,
      w.w_state           AS region_state,
      ib.ib_lower_bound   AS income_lower,
      SUM(cs.cs_net_paid)    AS total_net_paid,
      SUM(cs.cs_net_profit)  AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM
      catalog_sales cs
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY
      p.p_promo_name,
      w.w_state,
      ib.ib_lower_bound
  ),
  full_combined AS (
    SELECT
      COALESCE(sa.promo_name, ca.promo_name)               AS promo_name,
      COALESCE(sa.region_state, ca.region_state)           AS region_state,
      COALESCE(sa.income_lower, ca.income_lower)           AS income_lower,
      COALESCE(sa.total_net_paid, 0) + COALESCE(ca.total_net_paid, 0) AS total_net_paid,
      COALESCE(sa.total_profit, 0) + COALESCE(ca.total_profit, 0)   AS total_profit,
      CASE WHEN (COALESCE(sa.total_profit,0) + COALESCE(ca.total_profit,0)) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM store_agg sa
    FULL OUTER JOIN catalog_agg ca
      ON sa.promo_name = ca.promo_name
     AND sa.income_lower = ca.income_lower
     AND sa.region_state = ca.region_state
  ),
  web_agg AS (
    SELECT
      p.p_promo_name      AS promo_name,
      ca.ca_state         AS region_state,
      ib.ib_lower_bound   AS income_lower,
      SUM(ws.ws_net_paid)    AS total_net_paid,
      SUM(ws.ws_net_profit)  AS total_profit,
      CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM
      web_sales ws TABLESAMPLE BERNOULLI (10)
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY
      p.p_promo_name,
      ca.ca_state,
      ib.ib_lower_bound
  ),
  cross_set AS (
    SELECT ib.ib_income_band_sk, v.flag
    FROM (SELECT ib_income_band_sk FROM income_band LIMIT 5) ib
    CROSS JOIN (VALUES (1), (2)) AS v(flag)
  )
SELECT
  fc.promo_name,
  fc.region_state,
  fc.income_lower,
  fc.total_net_paid,
  fc.total_profit,
  fc.profit_flag,
  cs.flag
FROM (
  SELECT * FROM full_combined
  UNION DISTINCT
  SELECT * FROM web_agg
) fc
CROSS JOIN cross_set cs
ORDER BY fc.total_net_paid DESC
OFFSET 10 LIMIT 100
