SELECT
    CONCAT(cc.cc_company_name, '-', s.s_state) AS company_state,
    cp.cp_type,
    d_sold.d_year * 100 + d_sold.d_moy AS year_month,
    CASE
        WHEN d_cc_open.d_year < d_sold.d_year THEN 'Opened_before_sale'
        ELSE 'Opened_after_sale'
    END AS open_vs_sale_flag,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS num_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(cs.cs_coupon_amt) AS total_coupon_amt
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year BETWEEN 1999 AND 2002
  AND cp.cp_type IN ('book', 'electronics', 'fashion')
GROUP BY
    CONCAT(cc.cc_company_name, '-', s.s_state),
    cp.cp_type,
    d_sold.d_year * 100 + d_sold.d_moy,
    CASE
        WHEN d_cc_open.d_year < d_sold.d_year THEN 'Opened_before_sale'
        ELSE 'Opened_after_sale'
    END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
