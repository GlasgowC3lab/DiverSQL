WITH filtered_sales AS (
  SELECT ws.*, td.t_hour, cd_bill.cd_gender AS bill_gender,
         hd_bill.hd_buy_potential AS bill_buy_potential,
         cd_ship.cd_gender AS ship_gender,
         hd_ship.hd_buy_potential AS ship_buy_potential
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  WHERE ws.ws_ext_discount_amt > 5.00
    AND td.t_hour BETWEEN 12 AND 18
    AND cd_bill.cd_gender IS NOT NULL
),
aggregated AS (
  SELECT
    t_hour,
    bill_gender,
    COUNT(*) AS total_transactions,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN bill_buy_potential <> ship_buy_potential THEN 1 ELSE 0 END) AS diff_buy_potential_cnt
  FROM filtered_sales
  GROUP BY t_hour, bill_gender
  HAVING SUM(ws_net_profit) > 0
)
SELECT
  t_hour,
  bill_gender,
  total_transactions,
  total_net_profit,
  avg_discount,
  diff_buy_potential_cnt,
  RANK() OVER (PARTITION BY bill_gender ORDER BY total_net_profit DESC) AS profit_rank_by_hour
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 50
