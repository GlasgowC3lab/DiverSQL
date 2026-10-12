WITH catalog_agg AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_warehouse_sk AS warehouse_sk,
        SUM(cs_net_profit) AS catalog_net_profit,
        SUM(cs_ext_discount_amt) AS catalog_total_discount,
        SUM(cs_quantity) AS catalog_qty,
        AVG(cs_sales_price) AS catalog_avg_sales_price
    FROM catalog_sales
    WHERE cs_promo_sk IN (843, 587)
      AND cs_sold_date_sk BETWEEN 2450815 AND 2451180
    GROUP BY cs_sold_date_sk, cs_item_sk, cs_warehouse_sk
),
web_agg AS (
    SELECT
        ws_sold_date_sk AS sold_date_sk,
        ws_item_sk AS item_sk,
        ws_warehouse_sk AS warehouse_sk,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_ext_discount_amt) AS web_total_discount,
        SUM(ws_quantity) AS web_qty,
        AVG(ws_sales_price) AS web_avg_sales_price
    FROM web_sales
    WHERE ws_promo_sk IN (843, 587)
      AND ws_sold_date_sk BETWEEN 2450815 AND 2451180
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_warehouse_sk
)
SELECT
    ca.sold_date_sk,
    ca.item_sk,
    ca.warehouse_sk,
    ca.catalog_net_profit,
    wa.web_net_profit,
    (ca.catalog_net_profit + wa.web_net_profit) AS total_net_profit,
    (ca.catalog_qty + wa.web_qty) AS total_qty,
    (ca.catalog_avg_sales_price * ca.catalog_qty + wa.web_avg_sales_price * wa.web_qty) / (ca.catalog_qty + wa.web_qty) AS weighted_avg_sales_price,
    CASE WHEN ca.catalog_net_profit = 0 THEN NULL
         ELSE wa.web_net_profit / ca.catalog_net_profit END AS web_to_catalog_profit_ratio,
    RANK() OVER (PARTITION BY ca.warehouse_sk ORDER BY (ca.catalog_net_profit + wa.web_net_profit) DESC) AS profit_rank
FROM catalog_agg ca
JOIN web_agg wa
    ON ca.sold_date_sk = wa.sold_date_sk
   AND ca.item_sk = wa.item_sk
   AND ca.warehouse_sk = wa.warehouse_sk
WHERE (ca.catalog_net_profit + wa.web_net_profit) > 0
ORDER BY ca.sold_date_sk, profit_rank
LIMIT 100
