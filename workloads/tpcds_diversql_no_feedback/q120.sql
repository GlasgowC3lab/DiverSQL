-- Goal: Identify the highest‑value return transactions for each shipping mode, retaining all shipping modes (even those with no returns) and all call centers (even those without matching returns). The query shows product and call‑center details, flags red‑colored items, ranks returns per ship mode, computes the previous return amount and a running total of return amount per ship mode.
WITH base AS (
    SELECT
        cr.cr_order_number               AS cr_order_number,
        cr.cr_return_amount              AS cr_return_amount,
        cr.cr_returned_time_sk           AS cr_returned_time_sk,
        cr.cr_return_quantity            AS cr_return_quantity,
        i.i_item_id                      AS i_item_id,
        i.i_product_name                 AS i_product_name,
        i.i_current_price                AS i_current_price,
        i.i_color                        AS i_color,
        inv.inv_quantity_on_hand         AS inv_quantity_on_hand,
        sm.sm_ship_mode_sk               AS sm_ship_mode_sk,
        sm.sm_carrier                    AS sm_carrier,
        cc.cc_name                       AS cc_name,
        cc.cc_state                      AS cc_state,
        cp.cp_catalog_page_number        AS cp_catalog_page_number,
        td.t_hour                        AS t_hour
    FROM catalog_returns cr
    LEFT JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    RIGHT OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    FULL OUTER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    LEFT JOIN customer cust_ret
        ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND i.i_current_price BETWEEN 20 AND 200
      AND cc.cc_state = 'CA'
      AND sm.sm_carrier IN ('FEDEX', 'MSC')
      AND td.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    cr_order_number,
    cr_return_amount,
    i_item_id,
    i_product_name,
    cc_name,
    cp_catalog_page_number,
    sm_carrier,
    t_hour,
    CASE WHEN i_color = 'Red' THEN 'R' ELSE 'Other' END AS color_group,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_sk ORDER BY cr_return_amount DESC) AS rn_mode,
    LAG(cr_return_amount) OVER (PARTITION BY sm_ship_mode_sk ORDER BY cr_returned_time_sk) AS lag_return_amount,
    SUM(cr_return_amount) OVER (
        PARTITION BY sm_ship_mode_sk
        ORDER BY cr_returned_time_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM base
ORDER BY sm_carrier, rn_mode
LIMIT 100
