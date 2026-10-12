WITH
agg_store_sales AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price) AS total_store_sales,
           COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
      AND ss_list_price > 100
    GROUP BY ss_item_sk
),
store_return_items AS (
    SELECT DISTINCT sr_item_sk
    FROM store_returns
    WHERE sr_return_amt > 50
),
web_return_items AS (
    SELECT DISTINCT wr_item_sk
    FROM web_returns
    WHERE wr_return_amt > 50
),
store_only_return_items AS (
    SELECT sr_item_sk
    FROM store_return_items
    EXCEPT
    SELECT wr_item_sk
    FROM web_return_items
),
price_brackets AS (
    SELECT 1 AS bracket UNION ALL SELECT 2 UNION ALL SELECT 3
),
color_dim AS (
    SELECT DISTINCT i_color
    FROM item
    WHERE i_color IS NOT NULL
    LIMIT 5
),
color_bracket AS (
    SELECT c.i_color, p.bracket
    FROM color_dim c
    CROSS JOIN price_brackets p
)
SELECT
    cc.cc_name,
    wsite.web_site_id,
    ws.ws_order_number,
    i.i_item_id,
    i.i_color,
    cb.bracket,
    d.d_year,
    agg.total_store_sales,
    agg.store_txn_cnt,
    SUM(ws.ws_net_paid) AS total_web_paid,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
    SUM(wr.wr_net_loss) AS total_web_return_loss
FROM agg_store_sales agg
JOIN item i
    ON agg.ss_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
JOIN color_bracket cb
    ON cb.i_color = i.i_color
WHERE cc.cc_class = 'large'
  AND cc.cc_state = 'CA'
  AND i.i_color = 'Red'
  AND wsite.web_country = 'United States'
  AND d.d_year = 2001
  AND i.i_current_price BETWEEN 50 AND 200
  AND agg.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
  AND i.i_item_sk IN (SELECT sr_item_sk FROM store_only_return_items)
  AND c.c_preferred_cust_flag = 'Y'
  AND ca.ca_state = 'CA'
GROUP BY
    cc.cc_name,
    wsite.web_site_id,
    ws.ws_order_number,
    i.i_item_id,
    i.i_color,
    cb.bracket,
    d.d_year,
    agg.total_store_sales,
    agg.store_txn_cnt
ORDER BY total_web_paid DESC
LIMIT 100
