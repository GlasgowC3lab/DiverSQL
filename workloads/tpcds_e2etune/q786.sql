WITH store_agg AS (
  SELECT
    td.t_hour AS hour_of_day,
    i.i_category AS category,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_quantity) AS store_quantity,
    AVG(ss.ss_ext_discount_amt) AS store_avg_discount
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk >= 4
    AND td.t_hour BETWEEN 9 AND 21
  GROUP BY td.t_hour, i.i_category
),
web_agg AS (
  SELECT
    td.t_hour AS hour_of_day,
    i.i_category AS category,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_quantity) AS web_quantity,
    AVG(ws.ws_ext_discount_amt) AS web_avg_discount
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk >= 4
    AND td.t_hour BETWEEN 9 AND 21
  GROUP BY td.t_hour, i.i_category
)
SELECT
  ca.hour_of_day,
  ca.category,
  COALESCE(sa.store_net_profit, 0) AS store_net_profit,
  COALESCE(wa.web_net_profit, 0) AS web_net_profit,
  (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
  COALESCE(sa.store_quantity, 0) AS store_quantity,
  COALESCE(wa.web_quantity, 0) AS web_quantity,
  (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
  COALESCE(sa.store_avg_discount, 0) AS store_avg_discount,
  COALESCE(wa.web_avg_discount, 0) AS web_avg_discount
FROM (
  SELECT DISTINCT hour_of_day, category FROM (
    SELECT hour_of_day, category FROM store_agg
    UNION
    SELECT hour_of_day, category FROM web_agg
  ) u
) ca
LEFT JOIN store_agg sa ON ca.hour_of_day = sa.hour_of_day AND ca.category = sa.category
LEFT JOIN web_agg wa ON ca.hour_of_day = wa.hour_of_day AND ca.category = wa.category
WHERE (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) > 50000
ORDER BY total_net_profit DESC
LIMIT 20
