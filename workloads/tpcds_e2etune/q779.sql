WITH catalog_agg AS (
  SELECT
    td.t_hour,
    hd.hd_income_band_sk,
    sum(cs.cs_net_profit) AS catalog_net_profit,
    sum(cs.cs_net_paid_inc_tax) AS catalog_sales,
    count(*) AS catalog_orders
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_net_profit > 0
    AND td.t_hour BETWEEN 8 AND 20
    AND hd.hd_buy_potential = 'HIGH'
  GROUP BY td.t_hour, hd.hd_income_band_sk
),
web_agg AS (
  SELECT
    td.t_hour,
    hd.hd_income_band_sk,
    sum(ws.ws_net_profit) AS web_net_profit,
    sum(ws.ws_net_paid_inc_tax) AS web_sales,
    count(*) AS web_orders
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE ws.ws_net_profit > 0
    AND td.t_hour BETWEEN 8 AND 20
    AND hd.hd_buy_potential = 'HIGH'
  GROUP BY td.t_hour, hd.hd_income_band_sk
)
SELECT
  coalesce(ca.t_hour, wa.t_hour) AS hour_of_day,
  coalesce(ca.hd_income_band_sk, wa.hd_income_band_sk) AS income_band,
  ca.catalog_net_profit,
  wa.web_net_profit,
  (coalesce(ca.catalog_net_profit, 0) + coalesce(wa.web_net_profit, 0)) AS total_net_profit,
  (coalesce(ca.catalog_sales, 0) + coalesce(wa.web_sales, 0)) AS total_sales,
  (coalesce(ca.catalog_orders, 0) + coalesce(wa.web_orders, 0)) AS total_orders
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.t_hour = wa.t_hour AND ca.hd_income_band_sk = wa.hd_income_band_sk
ORDER BY total_net_profit DESC
LIMIT 20
