WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        td.t_hour,
        i.i_item_id,
        i.i_current_price,
        cd.cd_gender,
        p.p_promo_id,
        ws.ws_ext_list_price,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ws.ws_ext_sales_price AS ws_ext_sales_price
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
       AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE i.i_current_price BETWEEN 100 AND 500
      AND cd.cd_gender = 'M'
      AND p.p_promo_id = 'AAAAAAAACBAAAAAA'
      AND s.s_state = 'CA'
      AND ws.ws_ext_list_price > 1000
      AND td.t_hour BETWEEN 8 AND 17
      AND NOT EXISTS (
            SELECT 1 FROM inventory inv2
            WHERE inv2.inv_item_sk = i.i_item_sk
              AND inv2.inv_quantity_on_hand < 10
        )
),
agg_sales AS (
    SELECT
        s_store_id,
        t_hour,
        SUM(ss_ext_sales_price) AS store_sales,
        SUM(ws_ext_sales_price) AS web_sales,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(ss_ext_sales_price) > SUM(ws_ext_sales_price)
            THEN 'Store'
            ELSE 'Web'
        END AS higher_channel
    FROM base
    GROUP BY s_store_id, t_hour
)
SELECT
    s_store_id,
    t_hour,
    store_sales,
    web_sales,
    txn_count,
    higher_channel,
    (store_sales + web_sales) / txn_count AS avg_sales_per_txn
FROM agg_sales
WHERE store_sales > 10000
  AND web_sales > 5000
  AND (store_sales + web_sales) / txn_count > 200
ORDER BY avg_sales_per_txn DESC
LIMIT 100
