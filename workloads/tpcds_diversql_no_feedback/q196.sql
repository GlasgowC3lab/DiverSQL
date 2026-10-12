WITH joined AS (
    SELECT
        s.s_store_name AS s_store_name,
        sm.sm_type AS sm_type,
        hd_bill.hd_buy_potential AS hd_buy_potential,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        hd_bill.hd_vehicle_count AS hd_vehicle_count
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer cust_sr ON sr.sr_customer_sk = cust_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    WHERE hd_bill.hd_vehicle_count > 0
)
SELECT
    s_store_name,
    sm_type,
    hd_buy_potential,
    total_profit,
    rn
FROM (
    SELECT
        s_store_name,
        sm_type,
        hd_buy_potential,
        SUM(cs_net_profit + ws_net_profit - sr_net_loss - wr_net_loss) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(cs_net_profit + ws_net_profit - sr_net_loss - wr_net_loss) DESC) AS rn
    FROM joined
    GROUP BY s_store_name, sm_type, hd_buy_potential
) t
WHERE rn <= 5
ORDER BY total_profit DESC
LIMIT 100
