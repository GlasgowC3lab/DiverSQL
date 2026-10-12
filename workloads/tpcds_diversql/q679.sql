WITH
-- 10% Bernoulli sample of the fact table
ws_sample AS (
    SELECT ws_order_number,
           ws_sold_date_sk,
           ws_sold_time_sk,
           ws_bill_customer_sk,
           ws_bill_addr_sk,
           ws_warehouse_sk,
           ws_promo_sk,
           ws_ship_mode_sk,
           ws_quantity,
           ws_net_profit
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
),

-- Join every other selected table to the sampled fact table
joined_all AS (
    SELECT
        ws.ws_order_number,
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        w.w_warehouse_name,
        w.w_gmt_offset,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_type,
        CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ws.ws_quantity,
        ws.ws_net_profit,
        sr.sr_ticket_number,
        cr.cr_order_number,
        r.r_reason_desc AS store_return_reason,
        r2.r_reason_desc AS catalog_return_reason,
        cc.cc_name AS call_center_name,
        i.inv_quantity_on_hand
    FROM ws_sample ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.reason r2
        ON r2.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                -- predicate 1
      AND w.w_gmt_offset = -6.00                        -- predicate 2
      AND ca.ca_state = 'CA'                           -- predicate 3
      AND sm.sm_type = 'AIR'                           -- predicate 4
      AND p.p_discount_active = 'Y'                    -- predicate 5
      AND ws.ws_quantity > 5                           -- predicate 6
),

-- Orders that appear both in store returns and catalog returns for 2001
intersect_orders AS (
    SELECT sr.sr_ticket_number AS order_id
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT cr.cr_order_number AS order_id
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),

-- Keep only rows whose order number participates in the intersection
filtered_joined AS (
    SELECT *
    FROM joined_all ja
    WHERE EXISTS (
        SELECT 1 FROM intersect_orders io WHERE io.order_id = ja.ws_order_number
    )
),

-- First level aggregation (per year, warehouse and profit flag)
agg_by_year_warehouse AS (
    SELECT
        d_year,
        w_warehouse_name,
        profit_flag,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM filtered_joined
    GROUP BY d_year, w_warehouse_name, profit_flag
)

-- Final result with a ROW_NUMBER window function
SELECT
    d_year,
    w_warehouse_name,
    profit_flag,
    total_profit,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
FROM agg_by_year_warehouse
WHERE total_profit > 0
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
