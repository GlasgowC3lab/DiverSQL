SELECT
    cc.cc_state,
    cc.cc_manager,
    d.d_year,
    d.d_month_seq AS month,
    cp.cp_type,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_quantity) AS total_units_sold,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_units_returned,
    CASE WHEN SUM(cs.cs_quantity) = 0 THEN 0
         ELSE SUM(cr.cr_return_quantity) * 100.0 / SUM(cs.cs_quantity)
    END AS return_rate_pct,
    AVG(cs.cs_net_profit) AS avg_profit_per_order,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS sales_rank_state
FROM
    catalog_sales cs
JOIN
    call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN
    date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
JOIN
    catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    customer_demographics cd
      ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
     AND cr.cr_returned_date_sk = d.d_date_sk
WHERE
    cc.cc_state IN ('TN', 'LA', 'GA')
    AND d.d_year = 2020
    AND cp.cp_type = 'Electronics'
    AND cd.cd_gender = 'F'
    AND cd.cd_education_status = 'College'
GROUP BY
    cc.cc_state,
    cc.cc_manager,
    d.d_year,
    d.d_month_seq,
    cp.cp_type
HAVING
    SUM(cs.cs_net_paid_inc_tax) > 20000
ORDER BY
    total_sales DESC
LIMIT 100
