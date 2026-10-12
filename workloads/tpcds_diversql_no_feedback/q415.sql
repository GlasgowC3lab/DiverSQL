WITH joined AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_item_sk,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_paid AS store_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_id,
        hd.hd_buy_potential,
        w.w_city,
        sm.sm_ship_mode_id,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cr.cr_return_quantity,
        inv.inv_quantity_on_hand,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_paid AS web_net_paid,
        wp.wp_web_page_id,
        we.web_site_id
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_city = 'Seattle'
      AND p.p_promo_name LIKE 'Discount%'
      AND ss.ss_item_sk IN (SELECT i_item_sk FROM tpcds.item WHERE i_brand = 'Brand#12')
),
agg AS (
    SELECT
        d_year,
        i_category,
        w_city,
        p_promo_id,
        hd_buy_potential,
        sm_ship_mode_id,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(store_net_paid) AS total_store_sales,
        SUM(web_net_paid) AS total_web_sales,
        AVG(cs_ext_sales_price) AS avg_ext_sales_price,
        MIN(inv_quantity_on_hand) AS min_inventory_on_hand,
        MAX(cr_return_quantity) AS max_return_quantity
    FROM joined
    GROUP BY d_year, i_category, w_city, p_promo_id, hd_buy_potential, sm_ship_mode_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY order_cnt DESC) AS row_num,
    d_year,
    i_category,
    w_city,
    p_promo_id,
    hd_buy_potential,
    sm_ship_mode_id,
    order_cnt,
    total_store_sales,
    total_web_sales,
    avg_ext_sales_price,
    min_inventory_on_hand,
    max_return_quantity
FROM agg
ORDER BY row_num
LIMIT 100
