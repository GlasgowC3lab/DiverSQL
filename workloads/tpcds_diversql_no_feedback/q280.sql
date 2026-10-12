SELECT
    WEB.web_city,
    R.r_reason_desc,
    CD.cd_gender,
    HD.hd_buy_potential,
    SUM(SR.sr_net_loss) AS total_net_loss,
    SUM(WS.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT WS.ws_order_number) AS orders_count,
    AVG(SS.ss_quantity) AS avg_quantity_sold,
    MIN(IB.ib_lower_bound) AS min_income,
    MAX(IB.ib_upper_bound) AS max_income
FROM customer_address CA
JOIN store_sales SS
  ON SS.ss_addr_sk = CA.ca_address_sk
JOIN customer_demographics CD
  ON SS.ss_cdemo_sk = CD.cd_demo_sk
JOIN household_demographics HD
  ON SS.ss_hdemo_sk = HD.hd_demo_sk
JOIN income_band IB
  ON HD.hd_income_band_sk = IB.ib_income_band_sk
JOIN store_returns SR
  ON SR.sr_ticket_number = SS.ss_ticket_number
JOIN reason R
  ON SR.sr_reason_sk = R.r_reason_sk
JOIN web_returns WR
  ON WR.wr_reason_sk = R.r_reason_sk
JOIN web_sales WS
  ON WS.ws_order_number = WR.wr_order_number
JOIN ship_mode SM
  ON WS.ws_ship_mode_sk = SM.sm_ship_mode_sk
JOIN warehouse W
  ON WS.ws_warehouse_sk = W.w_warehouse_sk
JOIN web_site WEB
  ON WS.ws_web_site_sk = WEB.web_site_sk
WHERE
    CD.cd_marital_status IN ('S', 'M')
    AND IB.ib_upper_bound > 80000
    AND WEB.web_city = 'Salem'
    AND CA.ca_state = 'CA'
    AND W.w_warehouse_sk IN (SELECT ws_warehouse_sk FROM web_sales WHERE ws_net_paid > 1000)
GROUP BY
    WEB.web_city,
    R.r_reason_desc,
    CD.cd_gender,
    HD.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
