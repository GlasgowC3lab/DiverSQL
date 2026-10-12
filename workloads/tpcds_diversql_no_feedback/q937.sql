WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    date_dim.d_year,
    store.s_city,
    call_center.cc_company,
    COUNT(DISTINCT sampled_sales.ss_ticket_number) AS order_count,
    SUM(sampled_sales.ss_net_paid_inc_tax) AS total_net_paid,
    AVG(sampled_sales.ss_coupon_amt) AS avg_coupon_amount,
    CASE WHEN SUM(sampled_sales.ss_net_paid_inc_tax) > 10000 THEN 'High' ELSE 'Low' END AS revenue_category
FROM sampled_sales
JOIN date_dim
    ON sampled_sales.ss_sold_date_sk = date_dim.d_date_sk
JOIN store
    ON sampled_sales.ss_store_sk = store.s_store_sk
JOIN customer_address ca
    ON sampled_sales.ss_addr_sk = ca.ca_address_sk
JOIN call_center
    ON call_center.cc_closed_date_sk = date_dim.d_date_sk
JOIN catalog_sales
    ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
JOIN catalog_returns
    ON catalog_returns.cr_order_number = catalog_sales.cs_order_number
   AND catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
JOIN web_returns
    ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year = 2001
  AND store.s_city = 'Mount Pleasant'
  AND call_center.cc_company = 5
GROUP BY date_dim.d_year, store.s_city, call_center.cc_company
ORDER BY total_net_paid DESC
LIMIT 100
