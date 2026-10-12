WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    i.i_category,
    w.w_warehouse_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders_count,
    SUM(ss.ss_ext_sales_price) AS sales_total,
    SUM(wr.wr_return_amt) AS returns_total,
    inv_agg.total_quantity_on_hand,
    AVG(ss.ss_net_profit) AS avg_net_profit
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ss.ss_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND w.w_country = 'United States'
  AND ca.ca_state = 'CA'
  AND ss.ss_ext_sales_price > 1000
  AND wr.wr_return_quantity > 0
  AND cp.cp_type = 'Audio'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = ss.ss_item_sk
          AND ss2.ss_sold_date_sk = d.d_date_sk
          AND ss2.ss_quantity > 0
      )
GROUP BY d.d_year, i.i_category, w.w_warehouse_name, inv_agg.total_quantity_on_hand
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY sales_total DESC
LIMIT 100
