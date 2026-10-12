WITH web_sales_data AS (
   SELECT
     ws.ws_order_number,
     ws.ws_sold_date_sk,
     ws.ws_net_paid,
     ws.ws_net_profit,
     ws.ws_quantity,
     web_site.web_name,
     time_dim.t_hour,
     promotion.p_promo_name,
     'web' AS source_type,
     ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
   FROM web_sales ws
   JOIN time_dim ON ws.ws_sold_time_sk = time_dim.t_time_sk
   JOIN promotion ON ws.ws_promo_sk = promotion.p_promo_sk
   JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
   WHERE promotion.p_channel_catalog = 'N'
     AND promotion.p_channel_radio = 'N'
     AND time_dim.t_hour BETWEEN 12 AND 14
     AND EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
     )
),
catalog_sales_data AS (
   SELECT
     cs.cs_order_number AS ws_order_number,
     cs.cs_sold_date_sk AS ws_sold_date_sk,
     cs.cs_net_paid AS ws_net_paid,
     cs.cs_net_profit AS ws_net_profit,
     cs.cs_quantity AS ws_quantity,
     ca.ca_city AS web_name,
     time_dim.t_hour,
     promotion.p_promo_name,
     'catalog' AS source_type,
     ROW_NUMBER() OVER (PARTITION BY cs.cs_warehouse_sk ORDER BY cs.cs_net_paid DESC) AS rn
   FROM catalog_sales cs
   JOIN time_dim ON cs.cs_sold_time_sk = time_dim.t_time_sk
   JOIN promotion ON cs.cs_promo_sk = promotion.p_promo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE promotion.p_channel_tv = 'N'
     AND time_dim.t_hour BETWEEN 12 AND 14
     AND EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
          AND cs2.cs_order_number <> cs.cs_order_number
     )
)
SELECT *
FROM (
   SELECT
     ws_order_number,
     ws_sold_date_sk,
     ws_net_paid,
     ws_net_profit,
     ws_quantity,
     web_name,
     t_hour,
     p_promo_name,
     source_type
   FROM web_sales_data
   WHERE rn <= 5

   UNION ALL

   SELECT
     ws_order_number,
     ws_sold_date_sk,
     ws_net_paid,
     ws_net_profit,
     ws_quantity,
     web_name,
     t_hour,
     p_promo_name,
     source_type
   FROM catalog_sales_data
   WHERE rn <= 5
) combined
ORDER BY source_type, ws_net_paid DESC
LIMIT 100
