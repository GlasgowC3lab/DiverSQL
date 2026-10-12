WITH
    cs_agg AS (
        SELECT cs_item_sk,
               SUM(cs_quantity) AS cs_quantity,
               SUM(cs_net_profit) AS cs_net_profit
        FROM catalog_sales
        GROUP BY cs_item_sk
    ),
    ws_agg AS (
        SELECT ws_item_sk,
               SUM(ws_quantity) AS ws_quantity,
               SUM(ws_net_profit) AS ws_net_profit
        FROM web_sales
        GROUP BY ws_item_sk
    ),
    ss_agg AS (
        SELECT ss_item_sk,
               SUM(ss_quantity) AS ss_quantity,
               SUM(ss_net_profit) AS ss_net_profit,
               COUNT(DISTINCT ss_store_sk) AS ss_store_count
        FROM store_sales
        GROUP BY ss_item_sk
    )
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_item_desc,
    length(i.i_item_desc) AS orig_desc_len,
    regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', '') AS clean_desc,
    length(regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', '')) AS clean_desc_len,
    cardinality(regexp_split(regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', ''), '\\s+')) AS word_count,
    substr(i.i_product_name, 1, 30) AS prod_name_prefix,
    replace(lower(i.i_product_name), ' ', '_') AS snake_prod_name,
    concat_ws('|',
        replace(lower(coalesce(i.i_brand, '')), ' ', ''),
        replace(lower(coalesce(i.i_color, '')), ' ', ''),
        replace(lower(coalesce(i.i_size, '')), ' ', ''),
        replace(lower(coalesce(i.i_formulation, '')), ' ', '')
    ) AS search_key,
    coalesce(cs.cs_quantity, 0) + coalesce(ws.ws_quantity, 0) + coalesce(ss.ss_quantity, 0) AS total_quantity,
    coalesce(cs.cs_net_profit, 0) + coalesce(ws.ws_net_profit, 0) + coalesce(ss.ss_net_profit, 0) AS total_net_profit,
    coalesce(ss.ss_store_count, 0) AS store_count,
    CASE WHEN regexp_like(i.i_item_desc, '\\d') THEN true ELSE false END AS has_digit_in_desc,
    substr(i.i_product_name, 1, 1) AS first_letter
FROM
    item i
LEFT JOIN cs_agg cs ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN ws_agg ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN ss_agg ss ON ss.ss_item_sk = i.i_item_sk
WHERE
    i.i_item_desc IS NOT NULL
    AND i.i_product_name IS NOT NULL
    AND length(i.i_item_desc) > 20
    AND regexp_like(i.i_item_desc, '[A-Za-z]')
ORDER BY
    total_net_profit DESC
LIMIT 100
