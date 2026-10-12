WITH
  customer_sales AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    HAVING SUM(cs.cs_ext_sales_price) > 5000
  ),
  customer_returns AS (
    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
    HAVING SUM(wr.wr_return_amt) > 1000
  ),
  common_customers AS (
    SELECT customer_sk FROM customer_sales
    INTERSECT
    SELECT customer_sk FROM customer_returns
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_state,
  i.i_category,
  i.i_brand,
  p.p_promo_id,
  CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Standard' END AS promo_type,
  cs.cs_sold_date_sk,
  d_sold.d_date,
  cs.cs_quantity,
  cs.cs_ext_sales_price,
  SUM(cs.cs_ext_sales_price) OVER (
    PARTITION BY c.c_customer_id
    ORDER BY cs.cs_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sales,
  ROW_NUMBER() OVER (
    PARTITION BY c.c_customer_id
    ORDER BY cs.cs_sold_date_sk DESC
  ) AS rn,
  inv.inv_quantity_on_hand,
  s.s_store_id,
  wp.wp_url,
  cp.cp_department
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN web_sales ws
  ON cs.cs_order_number = ws.ws_order_number
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND ca.ca_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cs.cs_ext_sales_price > 1000
  AND c.c_customer_sk IN (SELECT customer_sk FROM common_customers)
ORDER BY cs.cs_sold_date_sk DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
