SELECT
    ca.cp_department AS department,
    ca.i_brand AS brand,
    ca.catalog_net_profit,
    COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(ss.store_net_profit, 0) AS store_net_profit,
    COALESCE(ws.web_net_profit, 0) AS web_net_profit,
    COALESCE(wr.web_return_loss, 0) AS web_return_loss,
    (ca.catalog_net_profit - COALESCE(cr.catalog_return_loss, 0) + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_return_loss, 0)) AS net_profit_after_returns,
    (ca.catalog_quantity + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) + COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0)) AS total_quantity_sold,
    ((COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0)) / NULLIF((ca.catalog_quantity + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)), 0)) AS return_rate
FROM (
    SELECT cp.cp_department, i.i_brand, SUM(cs.cs_net_profit) AS catalog_net_profit, SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
      AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cp.cp_department, i.i_brand
) ca
LEFT JOIN (
    SELECT cp.cp_department, i.i_brand, SUM(cr.cr_net_loss) AS catalog_return_loss, SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cp.cp_department, i.i_brand
) cr ON ca.cp_department = cr.cp_department AND ca.i_brand = cr.i_brand
LEFT JOIN (
    SELECT i.i_brand, SUM(ss.ss_net_profit) AS store_net_profit, SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY i.i_brand
) ss ON ca.i_brand = ss.i_brand
LEFT JOIN (
    SELECT i.i_brand, SUM(ws.ws_net_profit) AS web_net_profit, SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY i.i_brand
) ws ON ca.i_brand = ws.i_brand
LEFT JOIN (
    SELECT i.i_brand, SUM(wr.wr_net_loss) AS web_return_loss, SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY i.i_brand
) wr ON ca.i_brand = wr.i_brand
WHERE (ca.catalog_quantity + COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 10
