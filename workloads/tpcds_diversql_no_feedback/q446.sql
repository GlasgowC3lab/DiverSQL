WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 17
      AND ws.ws_coupon_amt > 100
      AND sm.sm_type = 'AIR'
      AND wsit.web_state = 'CA'
      AND cd_bill.cd_gender = 'M'
      AND ws.ws_ship_mode_sk IN (
          SELECT sm2.sm_ship_mode_sk
          FROM ship_mode sm2
          WHERE sm2.sm_carrier = 'UPS'
      )
    GROUP BY GROUPING SETS (
        (ws.ws_web_site_sk, ws.ws_ship_mode_sk, ws.ws_sold_time_sk),
        (ws.ws_web_site_sk, ws.ws_ship_mode_sk),
        (ws.ws_web_site_sk),
        ()
    )
)
SELECT
    wsit.web_name,
    AVG(sa.total_profit) AS avg_profit,
    SUM(sa.order_cnt) AS total_orders,
    ROW_NUMBER() OVER (ORDER BY AVG(sa.total_profit) DESC) AS rn
FROM sales_agg sa
JOIN web_site wsit ON sa.ws_web_site_sk = wsit.web_site_sk
GROUP BY wsit.web_name
HAVING SUM(sa.order_cnt) > 50
ORDER BY avg_profit DESC
LIMIT 100
