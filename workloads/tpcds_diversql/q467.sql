WITH
cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        p.p_discount_active,
        cp.cp_department,
        sm.sm_type           AS ship_type,
        w.w_warehouse_name,
        r.r_reason_desc,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        t.t_hour,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN item i                   ON cs.cs_item_sk        = i.i_item_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number   = cs.cs_order_number
    LEFT JOIN reason r           ON cr.cr_reason_sk      = r.r_reason_sk
    WHERE i.i_category = 'shirts'
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 12
),
full_sales AS (
    SELECT
        b.*,                           -- all columns from cs_base
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_quantity   AS store_quantity,
        ss.ss_net_paid   AS store_net_paid
    FROM cs_base b
    FULL OUTER JOIN store_sales ss
        ON ss.ss_item_sk = b.i_item_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
),
web_part AS (
    SELECT
        b.cs_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        wsite.web_name,
        ws.ws_ship_mode_sk
    FROM cs_base b
    JOIN web_sales ws
        ON ws.ws_item_sk = b.i_item_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_quantity > 0
),
union_orders AS (
    SELECT cs_order_number AS order_id, cs_net_paid AS net_paid
    FROM catalog_sales
    UNION
    SELECT ss_ticket_number AS order_id, ss_net_paid AS net_paid
    FROM store_sales
),
intersect_orders AS (
    SELECT cs_order_number AS intersect_order
    FROM catalog_sales
    WHERE cs_quantity > 2
    INTERSECT
    SELECT ss_ticket_number
    FROM store_sales
    WHERE ss_quantity > 2
)
SELECT
    COALESCE(fs.cs_order_number, wp.cs_order_number)               AS order_number,
    COALESCE(fs.i_item_id, 'UNKNOWN')                               AS item_id,
    COALESCE(fs.c_customer_id, 'UNKNOWN')                           AS customer_id,
    COALESCE(fs.cs_net_paid, wp.ws_net_paid)                        AS net_paid,
    CASE WHEN COALESCE(fs.cs_net_profit, 0) > 0 THEN 'Profitable' ELSE 'Loss' END  AS profit_flag,
    CASE WHEN EXISTS (
            SELECT 1 FROM intersect_orders io
            WHERE io.intersect_order = COALESCE(fs.cs_order_number, wp.cs_order_number)
        ) THEN 1 ELSE 0 END                                         AS intersect_flag,
    RANK() OVER (PARTITION BY COALESCE(fs.i_category, 'UNKNOWN') ORDER BY COALESCE(fs.cs_net_paid, wp.ws_net_paid) DESC) AS category_rank,
    u.net_paid                                                       AS union_net_paid,
    fs.store_quantity,
    wp.ws_quantity,
    fs.s_store_name,
    wp.web_name
FROM full_sales fs
FULL OUTER JOIN web_part wp
    ON fs.cs_order_number = wp.cs_order_number
LEFT JOIN union_orders u
    ON u.order_id = COALESCE(fs.cs_order_number, wp.cs_order_number)
WHERE (fs.store_quantity > 0 OR wp.ws_quantity > 0)
  AND (fs.cs_quantity > 1 OR wp.ws_quantity > 1)
ORDER BY net_paid DESC
LIMIT 100
