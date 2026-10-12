WITH sales_agg AS (
   SELECT
       d.d_date,
       d.d_year,
       i.i_item_id,
       i.i_brand,
       ca.ca_state,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_quantity) AS total_qty
   FROM store_sales ss
   RIGHT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   RIGHT JOIN item i ON ss.ss_item_sk = i.i_item_sk
   RIGHT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 1905 AND 1915
     AND i.i_current_price > 20
     AND ca.ca_country = 'United States'
     AND ss.ss_coupon_amt > 10
     AND ss.ss_ext_tax < 50
     AND ss.ss_list_price <> 0
   GROUP BY d.d_date, d.d_year, i.i_item_id, i.i_brand, ca.ca_state
),
returns_agg AS (
   SELECT
       d.d_date,
       d.d_year,
       i.i_item_id,
       i.i_brand,
       ca.ca_state,
       cc.cc_name,
       cp.cp_department,
       w.w_warehouse_name,
       SUM(cr.cr_return_amount) AS total_returns,
       SUM(cr.cr_return_quantity) AS total_return_qty
   FROM catalog_returns cr
   RIGHT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   RIGHT JOIN item i ON cr.cr_item_sk = i.i_item_sk
   RIGHT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 1905 AND 1915
     AND i.i_current_price > 20
     AND ca.ca_state = 'CA'
     AND cr.cr_return_amount > 5
     AND cr.cr_fee > 0
     AND cp.cp_department = 'DEPARTMENT'
   GROUP BY d.d_date, d.d_year, i.i_item_id, i.i_brand, ca.ca_state,
            cc.cc_name, cp.cp_department, w.w_warehouse_name
),
combined AS (
   SELECT
       s.d_year AS d_year,
       s.i_brand AS i_brand,
       s.ca_state AS ca_state,
       s.total_sales,
       0.0 AS total_returns
   FROM sales_agg s
   UNION ALL
   SELECT
       r.d_year,
       r.i_brand,
       r.ca_state,
       0.0,
       r.total_returns
   FROM returns_agg r
)
SELECT
    d_year AS year,
    i_brand AS brand,
    ca_state AS state,
    SUM(total_sales) AS total_sales,
    SUM(total_returns) AS total_returns,
    (SUM(total_sales) - SUM(total_returns)) AS net_amount,
    RANK() OVER (ORDER BY (SUM(total_sales) - SUM(total_returns)) DESC) AS sales_rank
FROM combined
GROUP BY CUBE (d_year, i_brand, ca_state)
HAVING (SUM(total_sales) - SUM(total_returns)) > 0
ORDER BY net_amount DESC
LIMIT 100
