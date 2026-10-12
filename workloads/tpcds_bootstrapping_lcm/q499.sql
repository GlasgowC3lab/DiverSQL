WITH returns_by_date AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_state,
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    d_sold.d_date AS sales_date,
    d_cc_open.d_year AS cc_open_year,
    d_cc_close.d_year AS cc_close_year,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MAX(cs.cs_net_paid_inc_tax) AS max_net_paid_inc_tax,
    MIN(cc.cc_tax_percentage) AS min_cc_tax_percentage,
    MAX(s.s_tax_percentage) AS max_store_tax_percentage,
    COALESCE(rbd.total_return_amt, 0) AS total_return_amt,
    COALESCE(rbd.total_return_qty, 0) AS total_return_qty,
    COALESCE(rbd.return_cnt, 0) AS return_cnt
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_close.d_date_sk
LEFT JOIN returns_by_date rbd
    ON rbd.return_date_sk = d_sold.d_date_sk
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_state,
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_date,
    d_cc_open.d_year,
    d_cc_close.d_year,
    d_ship.d_year,
    d_ship.d_month_seq,
    rbd.total_return_amt,
    rbd.total_return_qty,
    rbd.return_cnt
