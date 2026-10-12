/*
  Goal: Calculate per‑item yearly net sales and profit from store sales, and enrich the result with
  catalog order counts, web order counts, distinct promotion‑word count and total inventory on hand.
  All ten selected TPC‑DS tables are joined (using the allowed join rules), with the inventory table
  joined via a FULL OUTER JOIN and the promotion text expanded via UNNEST. A pre‑aggregation CTE
  (ss_agg) summarises store‑sales before the main query.
*/
WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        d.d_year,
        SUM(ss.ss_net_paid)   AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_year
),
promo_words AS (
    SELECT DISTINCT
        p.p_promo_sk,
        w AS word
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_channel_details, ' ')) AS t(w)
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ss_agg.d_year,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)       AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number)       AS web_order_cnt,
    COUNT(DISTINCT pw.word)                  AS promo_word_cnt,
    SUM(inv.inv_quantity_on_hand)            AS total_inventory_on_hand
FROM ss_agg
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs
    ON i.i_item_sk = cs.cs_item_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
FULL OUTER JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN promo_words pw
    ON p.p_promo_sk = pw.p_promo_sk
WHERE d_cs_sold.d_date = DATE '2001-01-01'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    ss_agg.d_year,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100
