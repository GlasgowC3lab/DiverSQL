WITH sales_by_cc_store AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_count,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_coupon_amt) AS total_coupon
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    sbcs.cc_name,
    sbcs.s_store_name,
    sbcs.d_year,
    sbcs.d_month_seq,
    sbcs.total_net_paid,
    sbcs.total_net_profit,
    ws.web_name,
    ws.web_tax_percentage,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    d_web_close.d_date AS web_close_date
FROM sales_by_cc_store sbcs
JOIN call_center cc
    ON sbcs.cc_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE sbcs.d_year = 2001
ORDER BY sbcs.total_net_paid DESC
LIMIT 100
