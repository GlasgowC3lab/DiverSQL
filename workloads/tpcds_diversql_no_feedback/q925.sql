WITH filtered_items AS (
    SELECT i_item_sk, i_product_name, i_current_price
    FROM item
    WHERE i_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    )
)
SELECT
    fi.i_item_sk,
    fi.i_product_name,
    w.w_warehouse_name,
    d_sold.d_date AS sold_date,
    cp.cp_department,
    wp.wp_url,
    cd.cd_gender,
    hd.hd_income_band_sk,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = fi.i_item_sk
    ) AS total_return_amount,
    (
        SELECT COUNT(*)
        FROM reason r2
        JOIN store_returns sr3 ON sr3.sr_reason_sk = r2.r_reason_sk
        WHERE sr3.sr_item_sk = fi.i_item_sk
    ) AS return_reason_count
FROM web_sales ws
JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    AND cp.cp_end_date_sk = d_wp_creation.d_date_sk
JOIN store_returns sr ON sr.sr_item_sk = fi.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = fi.i_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
GROUP BY
    fi.i_item_sk,
    fi.i_product_name,
    w.w_warehouse_name,
    d_sold.d_date,
    cp.cp_department,
    wp.wp_url,
    cd.cd_gender,
    hd.hd_income_band_sk
ORDER BY total_quantity DESC
LIMIT 100
