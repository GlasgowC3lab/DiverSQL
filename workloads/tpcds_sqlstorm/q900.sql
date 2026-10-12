SELECT
    d.d_year,
    cc.cc_market_manager,
    cp.cp_catalog_number,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_qty
FROM
    catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    d.d_year BETWEEN 1999 AND 2001
GROUP BY
    d.d_year,
    cc.cc_market_manager,
    cp.cp_catalog_number
ORDER BY
    d.d_year,
    total_sales DESC
LIMIT 10
