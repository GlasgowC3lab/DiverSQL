WITH filtered_items AS (
    SELECT i_item_sk
    FROM tpcds.item
    WHERE i_category = 'Electronics'
)
SELECT
    c1.c_customer_sk,
    c1.c_last_name,
    d1.d_date,
    i1.i_product_name,
    s1.s_store_name,
    ws1.ws_net_paid,
    CASE WHEN ws1.ws_net_paid > 1000 THEN 'High' ELSE 'Low' END AS payment_category,
    SUM(ws1.ws_net_paid) OVER (
        PARTITION BY c1.c_customer_sk
        ORDER BY d1.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_customer_sales,
    ROW_NUMBER() OVER (
        PARTITION BY d1.d_year
        ORDER BY ws1.ws_net_paid DESC
    ) AS yearly_sales_rank
FROM tpcds.store_sales ss1
JOIN tpcds.date_dim d1
  ON ss1.ss_sold_date_sk = d1.d_date_sk
JOIN tpcds.item i1
  ON ss1.ss_item_sk = i1.i_item_sk
JOIN tpcds.customer c1
  ON ss1.ss_customer_sk = c1.c_customer_sk
JOIN tpcds.customer_address ca1
  ON ss1.ss_addr_sk = ca1.ca_address_sk
JOIN tpcds.customer_demographics cd1
  ON ss1.ss_cdemo_sk = cd1.cd_demo_sk
JOIN tpcds.household_demographics hd1
  ON ss1.ss_hdemo_sk = hd1.hd_demo_sk
JOIN tpcds.income_band ib1
  ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
JOIN tpcds.store s1
  ON ss1.ss_store_sk = s1.s_store_sk
JOIN tpcds.inventory inv1
  ON inv1.inv_item_sk = i1.i_item_sk
 AND inv1.inv_date_sk = d1.d_date_sk
JOIN tpcds.web_sales ws1
  ON ws1.ws_item_sk = i1.i_item_sk
 AND ws1.ws_sold_date_sk = d1.d_date_sk
JOIN tpcds.web_page wp1
  ON ws1.ws_web_page_sk = wp1.wp_web_page_sk
JOIN tpcds.web_returns wr1
  ON wr1.wr_item_sk = i1.i_item_sk
 AND wr1.wr_returned_date_sk = d1.d_date_sk
 AND wr1.wr_order_number = ws1.ws_order_number
JOIN tpcds.reason r1
  ON wr1.wr_reason_sk = r1.r_reason_sk
WHERE d1.d_year = 2001
  AND s1.s_state = 'CA'
  AND c1.c_last_name LIKE 'B%'
  AND i1.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
  AND ib1.ib_upper_bound > 50000
ORDER BY cumulative_customer_sales DESC
LIMIT 100
