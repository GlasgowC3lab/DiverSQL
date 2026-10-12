WITH
    catalog_agg AS (
        SELECT
            cr_ship_mode_sk,
            cr_warehouse_sk,
            SUM(cr_net_loss) AS total_catalog_net_loss,
            SUM(cr_return_quantity) AS total_catalog_qty
        FROM catalog_returns
        WHERE cr_return_amount > 150
          AND cr_return_quantity >= 1
        GROUP BY cr_ship_mode_sk, cr_warehouse_sk
    ),
    store_agg AS (
        SELECT
            sr_hdemo_sk,
            sr_addr_sk,
            SUM(sr_net_loss) AS total_store_net_loss,
            SUM(sr_return_quantity) AS total_store_qty
        FROM store_returns
        WHERE sr_return_quantity > 1
          AND sr_store_credit > 10
        GROUP BY sr_hdemo_sk, sr_addr_sk
    ),
    web_agg AS (
        SELECT
            ws_ship_mode_sk,
            ws_warehouse_sk,
            SUM(ws_net_profit) AS total_web_profit,
            SUM(ws_ext_tax) AS total_web_tax
        FROM web_sales
        WHERE ws_ext_tax > 50
          AND ws_quantity >= 2
        GROUP BY ws_ship_mode_sk, ws_warehouse_sk
    ),
    small_dim AS (
        SELECT sm_ship_mode_sk, sm_type
        FROM ship_mode
        WHERE sm_type IN ('Air', 'Ocean')
    ),
    multiplier AS (
        SELECT 1 AS mult UNION ALL SELECT 2 UNION ALL SELECT 3
    )
SELECT
    sm_cat.sm_type AS catalog_ship_mode,
    w_cat.w_state AS catalog_warehouse_state,
    sm_web.sm_type AS web_ship_mode,
    w_web.w_state AS web_warehouse_state,
    ca.ca_city,
    hd.hd_buy_potential,
    ca.ca_gmt_offset,
    cat_agg.total_catalog_net_loss * mult.mult AS scaled_catalog_loss,
    store_agg.total_store_net_loss,
    web_agg.total_web_profit,
    (cat_agg.total_catalog_net_loss + store_agg.total_store_net_loss) AS combined_return_loss,
    (cat_agg.total_catalog_net_loss + store_agg.total_store_net_loss) / NULLIF(web_agg.total_web_profit, 0) AS loss_to_profit_ratio,
    sd.sm_type AS small_dim_ship_type,
    mult.mult
FROM catalog_agg cat_agg
JOIN ship_mode sm_cat ON cat_agg.cr_ship_mode_sk = sm_cat.sm_ship_mode_sk
JOIN warehouse w_cat ON cat_agg.cr_warehouse_sk = w_cat.w_warehouse_sk
CROSS JOIN store_agg
JOIN household_demographics hd ON store_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON store_agg.sr_addr_sk = ca.ca_address_sk
CROSS JOIN web_agg
JOIN ship_mode sm_web ON web_agg.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN warehouse w_web ON web_agg.ws_warehouse_sk = w_web.w_warehouse_sk
CROSS JOIN small_dim sd
CROSS JOIN multiplier mult
WHERE ca.ca_street_type = 'Drive'
  AND ca.ca_gmt_offset = -5.00
  AND sm_cat.sm_type = 'Air'
  AND w_cat.w_state = 'CA'
LIMIT 100
