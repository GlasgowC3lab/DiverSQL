WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    s.s_store_name,
    i.i_product_name,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ss.ss_net_paid,
    cr.cr_return_amount,
    wr.wr_return_amt,
    inv_agg.total_qty_on_hand,
    RANK() OVER (PARTITION BY s.s_state ORDER BY ss.ss_net_paid DESC) AS state_sales_rank,
    CASE
        WHEN cr.cr_return_amount > 0 THEN 'Catalog Return'
        WHEN wr.wr_return_amt > 0 THEN 'Web Return'
        ELSE 'Sale'
    END AS transaction_type
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk

/* Catalog returns and related dimensions */
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
LEFT JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk

/* Web sales and related dimensions */
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
LEFT JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk

/* Web returns and related dimensions */
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
LEFT JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk

WHERE
    s.s_market_manager = 'Richard Greene'
    AND wp.wp_image_count > 2
    AND i.i_current_price BETWEEN 10 AND 100
    AND s.s_rec_end_date > DATE '2000-01-01'
    AND wp.wp_rec_end_date < DATE '2001-01-01'
GROUP BY
    s.s_store_name,
    i.i_product_name,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ss.ss_net_paid,
    cr.cr_return_amount,
    wr.wr_return_amt,
    inv_agg.total_qty_on_hand,
    s.s_state
HAVING
    SUM(ss.ss_net_paid) > 1000
ORDER BY
    state_sales_rank,
    ss.ss_net_paid DESC
LIMIT 100
