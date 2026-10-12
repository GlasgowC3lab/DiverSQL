WITH sales_a AS (
    SELECT i.i_brand,
           sm.sm_type,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(COALESCE(wr.wr_return_amt, 0)) AS return_amt,
           COUNT(*) AS cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Books'
      AND cs.cs_quantity > 2
      AND ca_bill.ca_state = 'CA'
      AND cs.cs_ship_date_sk BETWEEN 2450000 AND 2450500
      AND wp.wp_type = 'home'
      AND wp.wp_rec_start_date = DATE '2000-09-03'
      AND wr.wr_return_quantity > 0
    GROUP BY i.i_brand, sm.sm_type
),
sales_b AS (
    SELECT i.i_brand,
           sm.sm_type,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(COALESCE(wr.wr_return_amt, 0)) AS return_amt,
           COUNT(*) AS cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Electronics'
      AND cs.cs_quantity <= 5
      AND ca_ship.ca_state = 'TX'
      AND cs.cs_ship_date_sk BETWEEN 2450600 AND 2451000
      AND wp.wp_type = 'product'
      AND wp.wp_rec_end_date = DATE '2001-09-02'
      AND wr.wr_return_quantity > 1
    GROUP BY i.i_brand, sm.sm_type
),
union_all AS (
    SELECT i_brand, sm_type, net_paid, return_amt, cnt FROM sales_a
    UNION DISTINCT
    SELECT i_brand, sm_type, net_paid, return_amt, cnt FROM sales_b
)
SELECT i_brand,
       sm_type,
       SUM(net_paid) AS total_net_paid,
       SUM(return_amt) AS total_return_amount,
       SUM(cnt) AS total_transactions,
       AVG(net_paid) AS avg_net_per_group
FROM union_all
GROUP BY i_brand, sm_type
HAVING SUM(net_paid) > 10000
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
