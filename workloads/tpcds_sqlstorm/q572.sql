WITH sales_by_channel AS (
    SELECT 'store' AS channel,
           ss_item_sk AS item_sk,
           ss_store_sk AS store_sk,
           SUM(ss_net_paid) AS net_paid,
           SUM(ss_quantity) AS quantity,
           COUNT(DISTINCT ss_ticket_number) AS txn_cnt,
           MAX(ss_sold_date_sk) AS latest_date
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2002
          AND d_month_seq BETWEEN 121 AND 124
    )
    GROUP BY ss_item_sk, ss_store_sk

    UNION ALL

    SELECT 'catalog' AS channel,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS store_sk,
           SUM(cs_net_paid) AS net_paid,
           SUM(cs_quantity) AS quantity,
           COUNT(DISTINCT cs_order_number) AS txn_cnt,
           MAX(cs_sold_date_sk) AS latest_date
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2002
          AND d_month_seq BETWEEN 121 AND 124
    )
    GROUP BY cs_item_sk, cs_call_center_sk

    UNION ALL

    SELECT 'web' AS channel,
           ws_item_sk AS item_sk,
           ws_web_page_sk AS store_sk,
           SUM(ws_net_paid) AS net_paid,
           SUM(ws_quantity) AS quantity,
           COUNT(DISTINCT ws_order_number) AS txn_cnt,
           MAX(ws_sold_date_sk) AS latest_date
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2002
          AND d_month_seq BETWEEN 121 AND 124
    )
    GROUP BY ws_item_sk, ws_web_page_sk
),
item_details AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           i.i_class,
           i.i_brand,
           COALESCE(i.i_color, 'UNKNOWN') AS color,
           CONCAT(i.i_brand, '-', i.i_size) AS brand_size
    FROM item i
),
sales_ranked AS (
    SELECT sbc.channel,
           id.i_item_id,
           id.i_product_name,
           id.i_category,
           sbc.item_sk,
           sbc.store_sk,
           sbc.net_paid,
           sbc.quantity,
           sbc.txn_cnt,
           sbc.latest_date,
           CASE 
               WHEN sbc.net_paid IS NULL THEN NULL
               ELSE sbc.net_paid / NULLIF(sbc.quantity, 0)
           END AS avg_price,
           ROW_NUMBER() OVER (PARTITION BY sbc.channel ORDER BY sbc.net_paid DESC) AS rn,
           RANK() OVER (ORDER BY sbc.net_paid DESC) AS overall_rank,
           PERCENT_RANK() OVER (ORDER BY sbc.net_paid DESC) AS pct_rank,
           CASE 
               WHEN sbc.net_paid IS NULL THEN 'NO_SALES'
               WHEN sbc.net_paid > 100000 THEN 'HIGH'
               WHEN sbc.net_paid > 10000 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS sales_tier,
           (SELECT MAX(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = sbc.item_sk) AS max_catalog_sales_price,
           (SELECT COUNT(*)
            FROM store_sales ss
            WHERE ss.ss_item_sk = sbc.item_sk
              AND ss.ss_sold_date_sk = sbc.latest_date) AS same_day_store_sales_cnt,
           id.color,
           id.brand_size
    FROM sales_by_channel sbc
    LEFT JOIN item_details id ON sbc.item_sk = id.i_item_sk
),
filtered AS (
    SELECT *
    FROM sales_ranked
    WHERE sales_tier IN ('HIGH', 'MEDIUM')
      AND (i_category LIKE 'A%' OR i_category IS NULL)
      AND (rn <= 10 OR net_paid IS NULL OR net_paid = 0)
      AND EXISTS (
          SELECT 1
          FROM date_dim d2
          WHERE d2.d_date_sk = latest_date
            AND d2.d_month_seq = (
                SELECT MAX(d3.d_month_seq)
                FROM date_dim d3
                WHERE d3.d_year = 2002
            )
      )
)
SELECT
    t.channel,
    t.i_item_id,
    t.i_product_name,
    t.i_category,
    t.sales_tier,
    t.net_paid,
    t.quantity,
    t.avg_price,
    t.rn,
    t.overall_rank,
    t.pct_rank,
    t.max_catalog_sales_price,
    t.same_day_store_sales_cnt,
    COALESCE(NULLIF(t.color, ''), 'N/A') AS display_color,
    t.brand_size,
    CASE 
        WHEN t.rn = 1 THEN 'TOP1'
        WHEN t.rn <= 5 THEN 'TOP5'
        ELSE 'OTHER'
    END AS rank_group,
    CONCAT(
        CASE 
            WHEN t.rn = 1 THEN 'TOP1'
            WHEN t.rn <= 5 THEN 'TOP5'
            ELSE 'OTHER'
        END,
        ':',
        t.sales_tier
    ) AS composite_tag,
    CASE 
        WHEN t.sales_tier = 'HIGH' THEN t.net_paid * 0.9
        ELSE t.net_paid
    END AS discounted_net,
    LEAST(COALESCE(t.net_paid, 0), 50000) * 0.1 + GREATEST(t.rn, 5) * 20 AS complex_metric
FROM (
    SELECT f.*, ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_paid DESC) AS channel_rn
    FROM filtered f
) t
WHERE t.channel_rn <= 3
ORDER BY t.channel, t.overall_rank
