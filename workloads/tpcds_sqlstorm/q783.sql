WITH catalog_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        sum(cs.cs_net_profit) AS net_profit,
        count(*) AS orders,
        sum(cs.cs_quantity) AS total_qty,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_ext_discount_amt) AS total_discount,
        max(cc.cc_name) FILTER (WHERE cs.cs_call_center_sk = cc.cc_call_center_sk) AS call_center_name,
        CAST(NULL AS varchar) AS store_name,
        CAST(NULL AS varchar) AS web_page_url,
        max(p.p_promo_name) FILTER (WHERE cs.cs_promo_sk = p.p_promo_sk) AS promo_name
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
store_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        sum(ss.ss_net_profit) AS net_profit,
        count(*) AS orders,
        sum(ss.ss_quantity) AS total_qty,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        CAST(NULL AS varchar) AS call_center_name,
        max(st.s_store_name) FILTER (WHERE ss.ss_store_sk = st.s_store_sk) AS store_name,
        CAST(NULL AS varchar) AS web_page_url,
        max(p.p_promo_name) FILTER (WHERE ss.ss_promo_sk = p.p_promo_sk) AS promo_name
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
web_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        sum(ws.ws_net_profit) AS net_profit,
        count(*) AS orders,
        sum(ws.ws_quantity) AS total_qty,
        sum(ws.ws_ext_sales_price) AS total_sales,
        sum(ws.ws_ext_discount_amt) AS total_discount,
        CAST(NULL AS varchar) AS call_center_name,
        CAST(NULL AS varchar) AS store_name,
        max(wp.wp_url) FILTER (WHERE ws.ws_web_page_sk = wp.wp_web_page_sk) AS web_page_url,
        max(p.p_promo_name) FILTER (WHERE ws.ws_promo_sk = p.p_promo_sk) AS promo_name
 FROM web_sales ws
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2001
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
combined AS (
 SELECT i_item_sk,
        i_product_name,
        d_year,
        sum(net_profit) AS total_net_profit,
        sum(orders) AS total_orders,
        sum(total_qty) AS total_quantity,
        sum(total_sales) AS total_sales,
        sum(total_discount) AS total_discount,
        array_agg(DISTINCT call_center_name) FILTER (WHERE call_center_name IS NOT NULL) AS call_centers,
        array_agg(DISTINCT store_name) FILTER (WHERE store_name IS NOT NULL) AS stores,
        array_agg(DISTINCT web_page_url) FILTER (WHERE web_page_url IS NOT NULL) AS web_pages,
        array_agg(DISTINCT promo_name) FILTER (WHERE promo_name IS NOT NULL) AS promotions
 FROM (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM web_agg
 ) u
 GROUP BY i_item_sk, i_product_name, d_year
),
ranked AS (
 SELECT *,
        row_number() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS rn
 FROM combined
)
SELECT d_year,
       i_item_sk,
       i_product_name,
       total_net_profit,
       total_orders,
       total_quantity,
       total_sales,
       total_discount,
       call_centers,
       stores,
       web_pages,
       promotions
FROM ranked
WHERE rn <= 10
ORDER BY d_year, total_net_profit DESC
