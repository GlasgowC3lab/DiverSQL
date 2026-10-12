WITH common_orders AS (
    SELECT cs_order_number FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_sales_price > 100
    INTERSECT
    SELECT cs_order_number FROM catalog_sales
    WHERE cs_net_profit > 50
)
SELECT
    d_sold.d_year,
    cp.cp_department,
    w.w_warehouse_name,
    cd_bill.cd_gender,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_ext_sales_price ELSE 0 END) AS profit_sales,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_status
FROM catalog_sales cs
JOIN common_orders co ON cs.cs_order_number = co.cs_order_number
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_sold.d_year = 2001
  AND cp.cp_department = 'Sports'
  AND w.w_state = 'CA'
  AND cd_bill.cd_credit_rating = 'Low Risk'
  AND ca_bill.ca_country = 'United States'
  AND cs.cs_quantity > 2
GROUP BY d_sold.d_year, cp.cp_department, w.w_warehouse_name, cd_bill.cd_gender
ORDER BY profit_sales DESC
LIMIT 100
