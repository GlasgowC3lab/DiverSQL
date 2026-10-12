WITH
base1 AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_net_paid AS net_paid,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category,
        sm.sm_type AS ship_type,
        w.w_warehouse_name AS warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE cs.cs_net_paid > 1000
),
base2 AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_net_paid AS net_paid,
        CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category,
        sm.sm_type AS ship_type,
        w.w_warehouse_name AS warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_paid > 1000
),
base3 AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_returned_date_sk AS sold_date_sk,
        wr.wr_net_loss AS net_paid,
        CASE WHEN wr.wr_return_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category,
        sm.sm_type AS ship_type,
        w.w_warehouse_name AS warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY wr.wr_net_loss DESC) AS rn
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wr.wr_net_loss > 0
),
intersect_orders AS (
    SELECT order_number FROM base1
    INTERSECT
    SELECT order_number FROM base2
),
union_all AS (
    SELECT order_number, sold_date_sk, net_paid, qty_category, ship_type, warehouse_name, rn FROM base1
    UNION DISTINCT
    SELECT order_number, sold_date_sk, net_paid, qty_category, ship_type, warehouse_name, rn FROM base2
    UNION DISTINCT
    SELECT order_number, sold_date_sk, net_paid, qty_category, ship_type, warehouse_name, rn FROM base3
),
ranked AS (
    SELECT
        u.order_number,
        u.sold_date_sk,
        u.net_paid,
        u.qty_category,
        u.ship_type,
        u.warehouse_name,
        CASE WHEN u.net_paid > 2000 THEN 'High' ELSE 'Medium' END AS revenue_tier,
        ROW_NUMBER() OVER (PARTITION BY u.warehouse_name ORDER BY u.net_paid DESC) AS rank_per_wh
    FROM union_all u
    JOIN intersect_orders io ON u.order_number = io.order_number
)
SELECT
    order_number,
    sold_date_sk,
    net_paid,
    qty_category,
    ship_type,
    warehouse_name,
    revenue_tier
FROM ranked
WHERE rank_per_wh <= 3
ORDER BY warehouse_name, net_paid DESC
OFFSET 0 LIMIT 10
