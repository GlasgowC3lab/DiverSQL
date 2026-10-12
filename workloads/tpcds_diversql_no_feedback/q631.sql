WITH cte_store_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS store_net_paid
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
)
SELECT
    d.d_year,
    i.i_category,
    cc.cc_name,
    cp.cp_type,
    SUM(ws.ws_net_paid)           AS web_sales_net,
    SUM(cs.cs_net_paid)           AS catalog_sales_net,
    SUM(cr.cr_net_loss)           AS catalog_return_loss,
    SUM(wr.wr_net_loss)           AS web_return_loss,
    SUM(ct.store_net_paid)        AS store_sales_net,
    SUM(unnest_val)               AS unnest_sum
FROM cte_store_sales ct
JOIN date_dim d ON ct.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ct.ss_item_sk = i.i_item_sk

-- catalog side
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                      AND cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                        AND cr.cr_item_sk = i.i_item_sk
                        AND cr.cr_returned_date_sk = d.d_date_sk

-- web side
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                  AND ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = i.i_item_sk
                      AND wr.wr_returned_date_sk = d.d_date_sk

-- customer demographics used twice under different aliases
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk

-- expand a derived array with UNNEST
CROSS JOIN UNNEST(ARRAY[CAST(ws.ws_quantity AS DOUBLE), CAST(ws.ws_sales_price AS DOUBLE)]) AS u(unnest_val)

GROUP BY GROUPING SETS (
    (d.d_year, i.i_category, cc.cc_name, cp.cp_type),
    (d.d_year, i.i_category),
    (cc.cc_name, cp.cp_type),
    ()
)
LIMIT 100
