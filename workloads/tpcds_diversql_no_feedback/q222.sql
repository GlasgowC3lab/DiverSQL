WITH
    inv_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk
        HAVING SUM(inv_quantity_on_hand) > 100
    ),
    customer_full AS (
        SELECT c.c_customer_sk,
               c.c_first_name,
               c.c_last_name,
               ca.ca_address_sk,
               ca.ca_city,
               ca.ca_state,
               ca.ca_location_type
        FROM customer c
        JOIN customer_address ca
          ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE c.c_birth_country = 'United States'
          AND ca.ca_location_type = 'apartment'
    ),
    promo_active AS (
        SELECT p_promo_sk
        FROM promotion
        WHERE p_discount_active = 'Y'
          AND p_cost < 5000
    ),
    web_site_f AS (
        SELECT web_site_sk,
               web_gmt_offset
        FROM web_site
        WHERE web_gmt_offset > 0
          AND web_mkt_class LIKE '%intermediat%'
    ),
    sales_data AS (
        SELECT ws.ws_bill_customer_sk AS cust_sk,
               ws.ws_sold_date_sk,
               ws.ws_item_sk,
               ws.ws_promo_sk,
               ws.ws_web_site_sk,
               ws.ws_net_paid,
               t.t_hour
        FROM web_sales ws
        JOIN time_dim t
          ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN item i
          ON ws.ws_item_sk = i.i_item_sk
        JOIN promo_active p
          ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site_f wsf
          ON ws.ws_web_site_sk = wsf.web_site_sk
        WHERE i.i_category = 'Furniture'
          AND t.t_hour BETWEEN 9 AND 17
    ),
    store_ret AS (
        SELECT sr.sr_customer_sk AS cust_sk,
               sr.sr_returned_date_sk,
               sr.sr_item_sk,
               sr.sr_return_amt,
               t.t_hour
        FROM store_returns sr
        JOIN time_dim t
          ON sr.sr_return_time_sk = t.t_time_sk
        JOIN item i
          ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_amt > 0
    ),
    web_ret AS (
        SELECT wr.wr_returning_customer_sk AS cust_sk,
               wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_amt,
               t.t_hour
        FROM web_returns wr
        JOIN time_dim t
          ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN item i
          ON wr.wr_item_sk = i.i_item_sk
        WHERE wr.wr_return_amt > 0
    ),
    cust_intersection AS (
        SELECT cust_sk FROM sales_data
        INTERSECT
        SELECT cust_sk FROM store_ret
    )
SELECT
    cf.c_customer_sk,
    cf.c_first_name,
    cf.c_last_name,
    cf.ca_city,
    cf.ca_state,
    i.i_item_id,
    i.i_product_name,
    inv_agg.total_qty,
    sd.ws_net_paid,
    sr.sr_return_amt,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (ORDER BY sd.ws_net_paid DESC) AS global_row_num
FROM cust_intersection ci
JOIN customer_full cf
  ON ci.cust_sk = cf.c_customer_sk
JOIN sales_data sd
  ON ci.cust_sk = sd.cust_sk
JOIN inv_agg
  ON sd.ws_item_sk = inv_agg.inv_item_sk
JOIN item i
  ON sd.ws_item_sk = i.i_item_sk
LEFT JOIN store_ret sr
  ON ci.cust_sk = sr.cust_sk
 AND sr.sr_item_sk = sd.ws_item_sk
LEFT JOIN web_ret wr
  ON ci.cust_sk = wr.cust_sk
 AND wr.wr_item_sk = sd.ws_item_sk
ORDER BY global_row_num
LIMIT 100
