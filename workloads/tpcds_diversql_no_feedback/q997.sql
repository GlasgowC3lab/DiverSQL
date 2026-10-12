/*
  Goal: Analyze catalog sales and related returns by combining all nine TPC‑DS tables, re‑using the household_demographics and customer_address dimensions under different aliases for billing and shipping roles, and also joining the return‑side dimensions. The query aggregates net profit and quantity, adds a LATERAL sub‑query that computes the total quantity sold for the same billing household demographic, filters to profitable groups, and orders the results.
*/
SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    sum(cs.cs_net_profit)                AS total_net_profit,
    sum(cs.cs_quantity)                  AS total_quantity,
    lt.demo_total_qty                    AS total_qty_for_bill_demo
FROM
    catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim td_ret
        ON cr.cr_returned_time_sk = td_ret.t_time_sk
    LEFT JOIN ship_mode sm_ret
        ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    LEFT JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN catalog_page cp_ret
        ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    LEFT JOIN LATERAL (
        SELECT sum(cs2.cs_quantity) AS demo_total_qty
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    ) lt ON true
GROUP BY
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    lt.demo_total_qty
HAVING
    sum(cs.cs_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
