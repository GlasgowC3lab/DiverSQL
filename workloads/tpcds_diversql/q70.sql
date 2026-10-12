WITH demographics_income AS (
   SELECT hd.hd_demo_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          hd.hd_buy_potential
   FROM household_demographics hd
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_upper_bound > 100000
),
store_info AS (
   SELECT s.s_store_sk,
          s.s_store_name,
          s.s_state,
          s.s_city
   FROM store s
   WHERE s.s_state = 'CA'
),
store_returns_agg AS (
   SELECT sr.sr_store_sk,
          sr.sr_hdemo_sk AS hd_demo_sk,
          SUM(sr.sr_net_loss) AS total_return_loss,
          COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%damaged%'
   GROUP BY sr.sr_store_sk, sr.sr_hdemo_sk
),
catalog_agg AS (
   SELECT cs.cs_bill_hdemo_sk AS hd_demo_sk,
          sm.sm_type AS ship_mode_type,
          SUM(cs.cs_net_profit) AS total_catalog_profit,
          SUM(cs.cs_quantity) AS total_catalog_qty
   FROM catalog_sales cs
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cs.cs_quantity > 5
   GROUP BY cs.cs_bill_hdemo_sk, sm.sm_type
),
web_agg AS (
   SELECT ws.ws_bill_hdemo_sk AS hd_demo_sk,
          sm.sm_type AS ship_mode_type,
          SUM(ws.ws_net_profit) AS total_web_profit,
          SUM(ws.ws_quantity) AS total_web_qty
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE ws.ws_quantity > 5
   GROUP BY ws.ws_bill_hdemo_sk, sm.sm_type
),
combined AS (
   SELECT
       si.s_store_name,
       si.s_state,
       di.ib_lower_bound,
       di.ib_upper_bound,
       di.hd_buy_potential,
       ca.ship_mode_type,
       COALESCE(ca.total_catalog_profit, 0) AS total_catalog_profit,
       COALESCE(wa.total_web_profit, 0) AS total_web_profit,
       COALESCE(sr.total_return_loss, 0) AS total_return_loss,
       (COALESCE(ca.total_catalog_profit, 0) + COALESCE(wa.total_web_profit, 0) - COALESCE(sr.total_return_loss, 0)) AS net_contribution
   FROM store_info si
   JOIN store_returns_agg sr ON sr.sr_store_sk = si.s_store_sk
   JOIN demographics_income di ON di.hd_demo_sk = sr.hd_demo_sk
   LEFT JOIN catalog_agg ca ON ca.hd_demo_sk = di.hd_demo_sk
   LEFT JOIN web_agg wa ON wa.hd_demo_sk = di.hd_demo_sk AND wa.ship_mode_type = ca.ship_mode_type
)
SELECT
    c.s_store_name,
    c.s_state,
    c.ib_lower_bound,
    c.ib_upper_bound,
    c.hd_buy_potential,
    c.ship_mode_type,
    c.total_catalog_profit,
    c.total_web_profit,
    c.total_return_loss,
    c.net_contribution,
    RANK() OVER (ORDER BY c.total_return_loss DESC) AS loss_rank,
    CASE
        WHEN c.net_contribution > (SELECT AVG(net_contribution) FROM combined) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS contribution_category
FROM combined c
ORDER BY loss_rank
LIMIT 100
