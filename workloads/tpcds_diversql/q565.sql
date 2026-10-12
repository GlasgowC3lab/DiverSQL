WITH
    intersect_orders AS (
        SELECT cr_order_number FROM catalog_returns
        INTERSECT
        SELECT wr_order_number FROM web_returns
    ),
    non_returned_sales AS (
        SELECT ws_order_number FROM web_sales
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ),
    base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            i.i_category,
            i.i_brand,
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            sm.sm_type,
            w.w_warehouse_name,
            p.p_promo_name,
            ws_site.web_name AS web_site_name,
            t.t_hour,
            cr.cr_return_amount,
            sr.sr_return_amt,
            wr.wr_return_amt,
            s.s_store_id
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
        LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
        LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    ),
    cross_set AS (
        SELECT s_small.s_store_id, v.num
        FROM (SELECT DISTINCT s_store_id FROM store LIMIT 5) s_small
        CROSS JOIN (VALUES (1), (2), (3)) AS v(num)
    )
SELECT
    b.i_category,
    b.web_site_name,
    SUM(b.ws_ext_sales_price) AS total_sales,
    SUM(b.ws_net_profit) AS total_profit,
    LAG(SUM(b.ws_net_profit)) OVER (PARTITION BY b.i_category ORDER BY SUM(b.ws_ext_sales_price) DESC) AS prev_category_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(b.ws_ext_sales_price) DESC) AS sales_rank,
    cs.s_store_id,
    cs.num
FROM base b
JOIN intersect_orders io ON b.ws_order_number = io.cr_order_number
JOIN non_returned_sales nrs ON b.ws_order_number = nrs.ws_order_number
CROSS JOIN cross_set cs
GROUP BY
    b.i_category,
    b.web_site_name,
    cs.s_store_id,
    cs.num
ORDER BY total_sales DESC
LIMIT 100
