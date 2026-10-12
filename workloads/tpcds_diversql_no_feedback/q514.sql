WITH filtered_cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_country = 'USA'
      AND sm.sm_code IN ('AIR', 'SEA')
      AND i.i_category = 'Sports'
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_quantity >= 2
      AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
),
filtered_ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ext_ship_cost,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE sm.sm_code = 'AIR'
      AND i.i_category = 'Sports'
      AND ws.ws_ext_ship_cost < 500
      AND ws.ws_quantity >= 1
      AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
      AND ws.ws_web_site_sk = 35
),
order_diff AS (
    SELECT cs_order_number
    FROM filtered_cs
    EXCEPT
    SELECT ws_order_number
    FROM filtered_ws
),
joined_all AS (
    SELECT
        cc.cc_name,
        sm.sm_type,
        i.i_category,
        ca.ca_state,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        inv.inv_quantity_on_hand
    FROM order_diff od
    JOIN catalog_sales cs ON cs.cs_order_number = od.cs_order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                    AND ws.ws_bill_addr_sk = ca.ca_address_sk
)
SELECT
    cc_name,
    sm_type,
    i_category,
    ca_state,
    COUNT(*) AS order_cnt,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    MIN(inv_quantity_on_hand) AS min_inventory,
    MAX(inv_quantity_on_hand) AS max_inventory
FROM joined_all
GROUP BY cc_name, sm_type, i_category, ca_state
ORDER BY total_sales DESC
LIMIT 100
