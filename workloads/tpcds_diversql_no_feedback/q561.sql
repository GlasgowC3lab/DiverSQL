WITH cat_ret AS (
        SELECT cr_item_sk,
               COUNT(*) AS cat_ret_cnt,
               SUM(cr_net_loss) AS cat_net_loss
        FROM catalog_returns
        GROUP BY cr_item_sk
    ),
    store_ret AS (
        SELECT sr_item_sk,
               sr_store_sk,
               COUNT(*) AS store_ret_cnt,
               SUM(sr_net_loss) AS store_net_loss
        FROM store_returns
        GROUP BY sr_item_sk, sr_store_sk
    )
SELECT
    i.i_category,
    i.i_product_name,
    regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS item_code,
    CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
    SUBSTRING(s.s_market_desc FROM 1 FOR 20) AS market_desc_snippet,
    cat_ret.cat_ret_cnt,
    cat_ret.cat_net_loss,
    store_ret.store_ret_cnt,
    store_ret.store_net_loss,
    (coalesce(cat_ret.cat_net_loss, 0) + coalesce(store_ret.store_net_loss, 0)) AS total_net_loss
FROM store_ret
JOIN item i ON store_ret.sr_item_sk = i.i_item_sk
JOIN store s ON store_ret.sr_store_sk = s.s_store_sk
LEFT JOIN cat_ret ON cat_ret.cr_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
  AND s.s_market_desc LIKE '%financial%'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = i.i_item_sk
          AND ws.ws_net_paid_inc_tax > 5000
    )
ORDER BY total_net_loss DESC
LIMIT 100
