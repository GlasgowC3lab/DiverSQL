WITH sales_union AS (
 SELECT 'store' AS channel,
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS location_sk,
        ss_item_sk AS item_sk,
        ss_promo_sk AS promo_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit
 FROM store_sales
 UNION ALL
 SELECT 'catalog' AS channel,
        cs_sold_date_sk AS date_sk,
        cs_call_center_sk AS location_sk,
        cs_item_sk AS item_sk,
        cs_promo_sk AS promo_sk,
        cs_quantity AS quantity,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit
 FROM catalog_sales
 UNION ALL
 SELECT 'web' AS channel,
        ws_sold_date_sk AS date_sk,
        ws_warehouse_sk AS location_sk,
        ws_item_sk AS item_sk,
        ws_promo_sk AS promo_sk,
        ws_quantity AS quantity,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit
 FROM web_sales
),
aggregated AS (
 SELECT d.d_year,
        i.i_category,
        i.i_class,
        s.channel,
        COALESCE(st.s_store_name, cc.cc_name, wh.w_warehouse_name) AS location_name,
        sum(s.quantity) AS total_quantity,
        sum(s.net_paid) AS total_net_paid,
        sum(s.net_profit) AS total_net_profit,
        avg(s.net_profit / nullif(s.net_paid, 0)) AS profit_margin,
        sum(CASE WHEN p.p_discount_active = 'Y' THEN s.net_paid * 0.1 ELSE 0 END) AS promo_discount_estimate,
        count(DISTINCT s.item_sk) AS distinct_items_sold,
        sum(s.net_profit) / nullif(count(DISTINCT s.item_sk), 0) AS profit_per_item
 FROM sales_union s
 JOIN date_dim d ON s.date_sk = d.d_date_sk
 JOIN item i ON s.item_sk = i.i_item_sk
 LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
 LEFT JOIN store st ON s.channel = 'store' AND s.location_sk = st.s_store_sk
 LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.location_sk = cc.cc_call_center_sk
 LEFT JOIN warehouse wh ON s.channel = 'web' AND s.location_sk = wh.w_warehouse_sk
 WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
 GROUP BY d.d_year, i.i_category, i.i_class, s.channel,
          COALESCE(st.s_store_name, cc.cc_name, wh.w_warehouse_name)
 HAVING sum(s.net_profit) > 100000
),
ranked AS (
 SELECT *,
        row_number() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS channel_rank
 FROM aggregated
)
SELECT d_year,
       i_category,
       i_class,
       channel,
       location_name,
       total_quantity,
       total_net_paid,
       total_net_profit,
       profit_margin,
       promo_discount_estimate,
       distinct_items_sold,
       profit_per_item,
       channel_rank
FROM ranked
WHERE channel_rank <= 10
ORDER BY channel, channel_rank
