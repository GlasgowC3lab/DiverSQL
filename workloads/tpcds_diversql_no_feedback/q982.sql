WITH catalog_data AS (
    SELECT
        td.t_hour AS hour,
        ca.ca_state AS state,
        cc.cc_name AS channel_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND cc.cc_market_manager = 'John Doe'
    GROUP BY td.t_hour, ca.ca_state, cc.cc_name
),
web_data AS (
    SELECT
        td.t_hour AS hour,
        ca.ca_state AS state,
        wp.wp_type AS channel_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND wp.wp_type = 'product'
    GROUP BY td.t_hour, ca.ca_state, wp.wp_type
)
SELECT * FROM catalog_data
UNION DISTINCT
SELECT * FROM web_data
ORDER BY hour, state, channel_name
