WITH
    cs AS (
        SELECT DISTINCT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit
        FROM catalog_sales cs
        WHERE cs.cs_quantity > (
            SELECT MAX(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = 2450816
        )
    ),
    ws AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_ship_mode_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_bill_addr_sk,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            ws.ws_web_site_sk
        FROM web_sales ws
    ),
    sr AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_store_sk,
            sr.sr_reason_sk,
            sr.sr_hdemo_sk,
            sr.sr_addr_sk
        FROM store_returns sr
        WHERE sr.sr_store_sk NOT IN (
            SELECT s.s_store_sk
            FROM store s
            WHERE s.s_state = 'TX'
        )
    )
SELECT
    s.s_state,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit + ws.ws_net_profit - sr.sr_return_amt) AS net_result
FROM sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN cs ON cs.cs_bill_hdemo_sk = hd_ret.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca_ret.ca_address_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN ws ON ws.ws_bill_hdemo_sk = hd_ret.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca_ret.ca_address_sk
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
GROUP BY ROLLUP (s.s_state, r.r_reason_desc)
ORDER BY s.s_state, r.r_reason_desc
LIMIT 100
