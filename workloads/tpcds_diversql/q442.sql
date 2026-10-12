WITH sampled_sales AS (
   SELECT ws_sold_date_sk,
          ws_sold_time_sk,
          ws_ship_date_sk,
          ws_item_sk,
          ws_bill_customer_sk,
          ws_bill_cdemo_sk,
          ws_bill_hdemo_sk,
          ws_bill_addr_sk,
          ws_ship_customer_sk,
          ws_ship_cdemo_sk,
          ws_ship_hdemo_sk,
          ws_ship_addr_sk,
          ws_web_page_sk,
          ws_web_site_sk,
          ws_ship_mode_sk,
          ws_warehouse_sk,
          ws_promo_sk,
          ws_order_number,
          ws_quantity,
          ws_wholesale_cost,
          ws_list_price,
          ws_sales_price,
          ws_ext_discount_amt,
          ws_ext_sales_price,
          ws_ext_wholesale_cost,
          ws_ext_list_price,
          ws_ext_tax,
          ws_coupon_amt,
          ws_ext_ship_cost,
          ws_net_paid,
          ws_net_paid_inc_tax,
          ws_net_paid_inc_ship,
          ws_net_paid_inc_ship_tax,
          ws_net_profit
   FROM web_sales TABLESAMPLE BERNOULLI (10)
),
sales_with_site AS (
   SELECT s.*, 
          w.web_site_id,
          w.web_state,
          w.web_gmt_offset,
          w.web_mkt_desc,
          (s.ws_list_price - s.ws_ext_discount_amt) AS adjusted_price,
          lt.line_total
   FROM sampled_sales s
   JOIN web_site w
     ON s.ws_web_site_sk = w.web_site_sk
   CROSS JOIN LATERAL (
       SELECT s.ws_quantity * (s.ws_list_price - s.ws_ext_discount_amt) AS line_total
   ) lt
   WHERE s.ws_list_price > 50
     AND s.ws_net_paid_inc_ship < 5000
     AND s.ws_quantity > 1
     AND w.web_state IN ('CA','NY','TX')
     AND w.web_gmt_offset BETWEEN -5 AND 5
),
site_agg AS (
   SELECT sws.web_site_id,
          sws.web_state,
          COUNT(*) AS order_cnt,
          SUM(sws.ws_net_paid_inc_ship) AS total_paid,
          SUM(sws.line_total) AS total_adj_sales
   FROM sales_with_site sws
   GROUP BY sws.web_site_id, sws.web_state
),
high_paid AS (
   SELECT web_site_id, web_state, total_paid, order_cnt
   FROM site_agg
   WHERE total_paid > 2000
),
low_order AS (
   SELECT web_site_id, web_state, total_paid, order_cnt
   FROM site_agg
   WHERE order_cnt < 5
),
filtered_sites AS (
   SELECT *
   FROM high_paid
   EXCEPT
   SELECT *
   FROM low_order
),
with_rownum AS (
   SELECT fs.*, 
          ROW_NUMBER() OVER (ORDER BY fs.total_paid DESC) AS rn
   FROM filtered_sites fs
)
SELECT wr.web_site_id,
       wr.web_state,
       wr.total_paid,
       wr.order_cnt,
       wr.rn
FROM with_rownum wr
ORDER BY wr.rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
