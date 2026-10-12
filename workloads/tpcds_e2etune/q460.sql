WITH sales_agg AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_coupon_amt) AS avg_coupon,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM
        catalog_sales cs
    JOIN
        call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN
        catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cc.cc_hours = '8AM-4PM'
        AND cc.cc_market_manager = 'Julius Tran'
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
        AND cc.cc_rec_end_date <= DATE '2001-12-31'
        AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
        AND cs.cs_quantity > 0
    GROUP BY
        cc.cc_state,
        cp.cp_department
    HAVING
        SUM(cs.cs_net_paid_inc_tax) > 100000
)
SELECT
    cc_state,
    cp_department,
    num_orders,
    total_net_paid,
    total_profit,
    avg_coupon,
    total_discount,
    total_quantity,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_profit DESC) AS profit_rank_by_state
FROM
    sales_agg
ORDER BY
    total_profit DESC
LIMIT 100
