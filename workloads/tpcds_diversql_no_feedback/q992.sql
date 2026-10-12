WITH item_sales AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name,
        i.i_item_desc,
        SUM(cs.cs_net_profit) AS total_net_profit,
        regexp_extract(i.i_product_name, '[0-9]+') AS product_code,
        CONCAT(i.i_product_name, '_', regexp_extract(i.i_product_name, '[0-9]+')) AS product_key
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_item_desc LIKE '%large%'
      AND regexp_like(i.i_product_name, '[0-9]{3,}')
    GROUP BY i.i_item_sk, i.i_product_name, i.i_item_desc
),
store_item AS (
    SELECT
        s.s_store_name,
        s.s_store_sk,
        i.i_item_sk AS item_sk,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY s.s_store_name, s.s_store_sk, i.i_item_sk
),
joined AS (
    SELECT
        si.s_store_name,
        isales.i_product_name,
        isales.product_code,
        isales.total_net_profit,
        si.total_return_amount,
        isales.product_key,
        ROW_NUMBER() OVER (PARTITION BY si.s_store_name ORDER BY isales.total_net_profit DESC) AS rn
    FROM store_item si
    JOIN item_sales isales
        ON si.item_sk = isales.item_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = isales.item_sk
          AND ws.ws_sold_date_sk > 2452000
    )
)
SELECT
    s_store_name,
    i_product_name,
    product_code,
    total_net_profit,
    total_return_amount,
    product_key
FROM joined
WHERE rn <= 3
ORDER BY s_store_name, total_net_profit DESC
LIMIT 100
