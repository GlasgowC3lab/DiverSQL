WITH joined AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        p.p_cost,
        w.w_state,
        hd_bill.hd_vehicle_count,
        d_sold.d_year,
        inv.inv_quantity_on_hand,
        ws.ws_list_price
    FROM catalog_sales cs
    RIGHT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    LEFT JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN customer_demographics cd_wr_refunded
        ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer_demographics cd_wr_returning
        ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    WHERE
        cp.cp_department = 'Sports'
        AND p.p_discount_active = 'Y'
        AND w.w_state = 'CA'
        AND hd_bill.hd_vehicle_count >= 2
        AND cs.cs_quantity > 5
        AND d_sold.d_year = 2001
        AND inv.inv_quantity_on_hand > 0
        AND ws.ws_list_price BETWEEN 100 AND 200
        AND cs.cs_ext_sales_price > (
            SELECT MAX(p_cost)
            FROM promotion
            WHERE p_purpose = 'Unknown'
        )
),
agg AS (
    SELECT
        cp_catalog_page_id,
        cp_department,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sale_rows
    FROM joined
    GROUP BY cp_catalog_page_id, cp_department
)
SELECT
    cp_catalog_page_id,
    cp_department,
    total_net_profit,
    total_quantity,
    sale_rows,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_profit DESC) AS dept_profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
