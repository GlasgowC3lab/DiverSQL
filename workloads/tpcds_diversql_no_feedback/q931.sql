/*
Goal: Analyze 2001 catalog sales by customer state, promotion, warehouse and catalog page, computing total quantity, net paid and average profit, flagging profit vs loss, and ranking states by quantity sold.
*/
WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
),
agg AS (
    SELECT
        d_sold.d_year                                            AS sold_year,
        d_ship.d_month_seq                                        AS ship_month_seq,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cc.cc_name,
        cp.cp_type,
        p.p_promo_name,
        w.w_warehouse_name,
        SUM(s.cs_quantity)                                        AS total_quantity,
        SUM(s.cs_net_paid)                                        AS total_net_paid,
        AVG(s.cs_net_profit)                                      AS avg_net_profit,
        CASE WHEN SUM(s.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator
    FROM sales_base s
    JOIN date_dim d_sold
        ON s.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON s.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t_sold
        ON s.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c
        ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON s.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON s.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON s.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON s.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = s.cs_order_number
        AND cr.cr_item_sk = s.cs_item_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND p.p_channel_press = 'N'
    GROUP BY
        d_sold.d_year,
        d_ship.d_month_seq,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cc.cc_name,
        cp.cp_type,
        p.p_promo_name,
        w.w_warehouse_name
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_quantity DESC) AS qty_rank
FROM agg
ORDER BY total_quantity DESC, profit_indicator
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
