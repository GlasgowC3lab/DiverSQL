WITH base AS (
   SELECT
       ws.ws_sold_date_sk,
       ws.ws_sold_time_sk,
       ws.ws_item_sk,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       i.i_item_id,
       i.i_current_price,
       i.i_rec_start_date,
       i.i_brand,
       i.i_item_desc,
       p.p_promo_id,
       p.p_promo_name,
       p.p_channel_tv,
       p.p_cost,
       wp.wp_web_page_id,
       wp.wp_type,
       c.c_customer_id,
       c.c_preferred_cust_flag,
       w.web_site_id,
       w.web_name,
       w.web_state,
       split(i.i_item_desc, ' ') AS desc_words
   FROM tpcds.web_sales ws
   JOIN tpcds.item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN tpcds.web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.web_site w
     ON ws.ws_web_site_sk = w.web_site_sk
   WHERE i.i_current_price > 20.00
     AND i.i_rec_start_date >= DATE '1999-01-01'
     AND p.p_channel_tv = 'N'
     AND p.p_cost < 2000.00
     AND wp.wp_type = 'Content'
     AND w.web_state = 'CA'
     AND c.c_preferred_cust_flag = 'Y'
     AND ws.ws_sold_time_sk IN (44494, 44795)
)

SELECT
    base.web_name,
    base.p_promo_name,
    base.i_brand,
    word,
    COUNT(DISTINCT base.ws_order_number) AS order_cnt,
    SUM(base.ws_ext_sales_price) AS total_sales,
    AVG(base.ws_net_profit) AS avg_profit,
    MIN(base.ws_ext_sales_price) AS min_sale,
    MAX(base.ws_ext_sales_price) AS max_sale,
    ROW_NUMBER() OVER (PARTITION BY base.web_name ORDER BY SUM(base.ws_ext_sales_price) DESC) AS rn
FROM base
CROSS JOIN UNNEST(base.desc_words) AS t(word)
GROUP BY
    base.web_name,
    base.p_promo_name,
    base.i_brand,
    word
ORDER BY total_sales DESC
LIMIT 100
