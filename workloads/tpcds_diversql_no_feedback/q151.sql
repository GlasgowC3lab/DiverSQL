WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        d_sold.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(ws.ws_net_paid) AS web_sales,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
        AND ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE cs.cs_sold_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 1998
    )
    GROUP BY GROUPING SETS (
        (c.c_customer_id, d_sold.d_year),
        (d_sold.d_year)
    )
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    c_customer_id,
    d_year,
    total_sales,
    num_orders,
    total_return_loss,
    web_sales,
    web_return_loss
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
