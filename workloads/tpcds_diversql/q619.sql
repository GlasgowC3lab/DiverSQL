WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),

joined_data AS (
    SELECT
        i.i_item_id,
        i.i_manufact,
        i.i_current_price,
        d.d_year,
        d.d_month_seq,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        cr.cr_return_amount,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        cc.cc_name,
        w.w_warehouse_name,
        hd.hd_income_band_sk,
        ca.ca_state,
        CASE 
            WHEN ss.ss_net_paid > 1000 THEN 'High'
            WHEN ss.ss_net_paid BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                   AND inv.inv_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price BETWEEN 20 AND 100
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND hd.hd_income_band_sk BETWEEN 3 AND 7
        AND cc.cc_gmt_offset > -5.00
)

SELECT
    i_item_id,
    i_manufact,
    d_year,
    d_month_seq,
    sales_category,
    SUM(ss_quantity) AS total_store_qty,
    SUM(ws_quantity) AS total_web_qty,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(i_current_price) AS avg_price,
    COUNT(DISTINCT w_warehouse_name) AS warehouse_count
FROM joined_data
GROUP BY
    i_item_id,
    i_manufact,
    d_year,
    d_month_seq,
    sales_category
HAVING
    SUM(ss_net_paid) > 5000
    AND SUM(ws_net_paid) > 3000
    AND COUNT(DISTINCT w_warehouse_name) >= 2
ORDER BY
    total_store_sales DESC,
    i_item_id
