SELECT
    d.d_year,
    d.d_month_seq,
    cp.cp_department,
    w.w_warehouse_name,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr_agg.return_amt) AS total_return_amount,
    SUM(sr_agg.store_return_total) AS total_store_return_amount,
    SUM(wr_agg.web_return_total) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM
    catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr_join
    ON cr_join.cr_order_number = cs.cs_order_number
   AND cr_join.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r
    ON cr_join.cr_reason_sk = r.r_reason_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_item_sk = cs.cs_item_sk
LEFT JOIN LATERAL (
    SELECT SUM(cr.cr_return_amount) AS return_amt
    FROM catalog_returns cr
    WHERE cr.cr_order_number = cs.cs_order_number
) AS cr_agg ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(sr.sr_return_amt) AS store_return_total
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk = cs.cs_sold_date_sk
) AS sr_agg ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(wr.wr_return_amt) AS web_return_total
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk = cs.cs_sold_date_sk
) AS wr_agg ON TRUE
WHERE
    d.d_year = 2001
    AND d.d_month_seq BETWEEN 1 AND 12
    AND t.t_hour BETWEEN 9 AND 17
    AND w.w_state = 'CA'
    AND cp.cp_department = 'Furniture'
    AND ca.ca_state = 'TX'
    AND i.inv_quantity_on_hand > 0
    AND r.r_reason_desc = 'Damaged'
GROUP BY
    d.d_year,
    d.d_month_seq,
    cp.cp_department,
    w.w_warehouse_name,
    r.r_reason_desc
ORDER BY
    total_sales DESC
LIMIT 100
