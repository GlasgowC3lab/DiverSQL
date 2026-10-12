WITH items_expanded AS (
    SELECT
        i.i_item_sk,
        i.i_formulation,
        i.i_color,
        ARRAY[i.i_formulation, i.i_color] AS attr_array
    FROM item i
)
SELECT
    d.d_year,
    s.s_state,
    SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales_amount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(COALESCE(ss.ss_ext_discount_amt, 0) + COALESCE(ws.ws_ext_discount_amt, 0)) AS avg_discount,
    MIN(inv.inv_quantity_on_hand) AS min_inventory,
    MAX(inv.inv_quantity_on_hand) AS max_inventory,
    attr
FROM
    catalog_returns cr
    FULL OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN items_expanded ie
        ON cr.cr_item_sk = ie.i_item_sk
    LEFT JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = cr.cr_item_sk
       AND inv.inv_warehouse_sk = cr.cr_warehouse_sk
       AND inv.inv_date_sk = cr.cr_returned_date_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN items_expanded ie_ss
        ON ss.ss_item_sk = ie_ss.i_item_sk
    LEFT JOIN customer c_ss
        ON ss.ss_customer_sk = c_ss.c_customer_sk
    LEFT JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN items_expanded ie_wr
        ON wr.wr_item_sk = ie_wr.i_item_sk
    LEFT JOIN customer c_wr
        ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
    LEFT JOIN customer_demographics cd_wr
        ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    LEFT JOIN items_expanded ie_ws
        ON ws.ws_item_sk = ie_ws.i_item_sk
    LEFT JOIN customer c_ws
        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    LEFT JOIN customer_demographics cd_ws
        ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    CROSS JOIN UNNEST(ie.attr_array) AS t(attr)
WHERE
    d.d_year = 2001
    AND ie.i_formulation = '85seashell1303417084'
    AND inv.inv_quantity_on_hand > 500
    AND cd.cd_dep_employed_count >= 3
    AND s.s_state = 'CA'
GROUP BY
    GROUPING SETS (
        (d.d_year, s.s_state, attr),
        (d.d_year, s.s_state),
        (d.d_year),
        (s.s_state),
        ()
    )
ORDER BY
    d.d_year DESC,
    s.s_state,
    total_return_amount DESC
LIMIT 100
