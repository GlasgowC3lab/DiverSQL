WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        p.p_promo_sk,
        p.p_promo_id
    FROM item i
    FULL OUTER JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
),
catalog_agg AS (
    SELECT
        ip.i_item_id AS item_id,
        ip.p_promo_id AS promo_id,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales,
        COUNT(cs.cs_order_number) AS order_cnt
    FROM item_promo ip
    LEFT JOIN catalog_sales cs
        ON ip.i_item_sk = cs.cs_item_sk
       AND ip.p_promo_sk = cs.cs_promo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 12
    GROUP BY ip.i_item_id, ip.p_promo_id
),
store_agg AS (
    SELECT
        ip.i_item_id AS item_id,
        ip.p_promo_id AS promo_id,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COUNT(ss.ss_ticket_number) AS order_cnt
    FROM item_promo ip
    LEFT JOIN store_sales ss
        ON ip.i_item_sk = ss.ss_item_sk
       AND ip.p_promo_sk = ss.ss_promo_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 12
    GROUP BY ip.i_item_id, ip.p_promo_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY combined.total_sales DESC) AS row_num,
    combined.source,
    combined.item_id,
    combined.promo_id,
    combined.total_sales,
    combined.order_cnt
FROM (
    SELECT 'catalog' AS source, item_id, promo_id, total_sales, order_cnt
    FROM catalog_agg
    UNION ALL
    SELECT 'store' AS source, item_id, promo_id, total_sales, order_cnt
    FROM store_agg
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
