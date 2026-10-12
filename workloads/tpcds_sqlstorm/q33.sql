WITH
    date_items AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            d.d_year,
            i.i_item_sk,
            i.i_product_name,
            i.i_brand,
            i.i_category
        FROM date_dim d
        CROSS JOIN LATERAL (
            SELECT i_item_sk, i_product_name, i_brand, i_category
            FROM item
            ORDER BY rand()
            LIMIT 10
        ) i
        WHERE d.d_year BETWEEN 2000 AND 2002
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_item_sk AS item_sk,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_profit,
            COUNT(*) AS store_txn_cnt,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS store_sales_rank
        FROM store_sales ss
        GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_item_sk AS item_sk,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_profit,
            COUNT(*) AS web_txn_cnt,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS web_sales_rank
        FROM web_sales ws
        GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
    ),
    catalog_sales_agg AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_item_sk AS item_sk,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            SUM(cs.cs_net_profit) AS catalog_profit,
            COUNT(*) AS catalog_txn_cnt,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS catalog_sales_rank
        FROM catalog_sales cs
        GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
    ),
    returns_agg AS (
        SELECT
            r.returned_date_sk AS date_sk,
            r.item_sk AS item_sk,
            SUM(r.net_loss) AS total_return_loss,
            COUNT(*) AS return_cnt
        FROM (
            SELECT sr_returned_date_sk AS returned_date_sk,
                   sr_item_sk AS item_sk,
                   sr_net_loss AS net_loss
            FROM store_returns
            UNION ALL
            SELECT wr_returned_date_sk,
                   wr_item_sk,
                   wr_net_loss
            FROM web_returns
            UNION ALL
            SELECT cr_returned_date_sk,
                   cr_item_sk,
                   cr_net_loss
            FROM catalog_returns
        ) r
        GROUP BY r.returned_date_sk, r.item_sk
    ),
    common_items AS (
        SELECT ss.ss_item_sk AS item_sk, ss.ss_sold_date_sk AS date_sk
        FROM store_sales ss
        INTERSECT
        SELECT ws.ws_item_sk, ws.ws_sold_date_sk
        FROM web_sales ws
    ),
    combined AS (
        SELECT
            di.d_date_sk,
            di.d_date,
            di.d_year,
            di.i_item_sk,
            di.i_product_name,
            di.i_brand,
            di.i_category,
            COALESCE(sa.store_net_paid, 0) AS store_net_paid,
            COALESCE(wa.web_net_paid, 0) AS web_net_paid,
            COALESCE(ca.catalog_net_paid, 0) AS catalog_net_paid,
            COALESCE(r.total_return_loss, 0) AS total_return_loss,
            COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
            COALESCE(wa.web_txn_cnt, 0) AS web_txn_cnt,
            COALESCE(ca.catalog_txn_cnt, 0) AS catalog_txn_cnt,
            COALESCE(sa.store_profit, 0) AS store_profit,
            COALESCE(wa.web_profit, 0) AS web_profit,
            COALESCE(ca.catalog_profit, 0) AS catalog_profit,
            CASE
                WHEN (COALESCE(sa.store_net_paid,0) + COALESCE(wa.web_net_paid,0) + COALESCE(ca.catalog_net_paid,0)) = 0 THEN NULL
                ELSE (COALESCE(sa.store_net_paid,0) + COALESCE(wa.web_net_paid,0) + COALESCE(ca.catalog_net_paid,0)) / NULLIF(COALESCE(r.total_return_loss,1),0)
            END AS revenue_per_return_loss,
            CONCAT_WS(' | ', di.i_product_name, di.i_brand, di.i_category) AS product_signature,
            ROW_NUMBER() OVER (PARTITION BY di.d_year ORDER BY (COALESCE(sa.store_net_paid,0) + COALESCE(wa.web_net_paid,0) + COALESCE(ca.catalog_net_paid,0)) DESC) AS yearly_rank,
            CASE WHEN EXISTS (
                SELECT 1
                FROM store_sales ss
                JOIN web_sales ws
                  ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
                 AND ss.ss_item_sk = ws.ws_item_sk
                WHERE ss.ss_sold_date_sk = di.d_date_sk
                  AND ss.ss_item_sk = di.i_item_sk
            ) THEN 1 ELSE 0 END AS common_item_flag_exists,
            CASE WHEN ci.item_sk IS NOT NULL THEN 1 ELSE 0 END AS common_item_flag_intersect
        FROM date_items di
        LEFT JOIN store_sales_agg sa ON di.d_date_sk = sa.date_sk AND di.i_item_sk = sa.item_sk
        LEFT JOIN web_sales_agg wa ON di.d_date_sk = wa.date_sk AND di.i_item_sk = wa.item_sk
        LEFT JOIN catalog_sales_agg ca ON di.d_date_sk = ca.date_sk AND di.i_item_sk = ca.item_sk
        LEFT JOIN returns_agg r ON di.d_date_sk = r.date_sk AND di.i_item_sk = r.item_sk
        LEFT JOIN common_items ci ON di.d_date_sk = ci.date_sk AND di.i_item_sk = ci.item_sk
    ),
    final AS (
        SELECT
            c.product_signature,
            c.d_date,
            c.store_net_paid,
            c.web_net_paid,
            c.catalog_net_paid,
            c.total_return_loss,
            c.revenue_per_return_loss,
            c.yearly_rank,
            c.common_item_flag_exists,
            c.common_item_flag_intersect,
            CASE
                WHEN c.revenue_per_return_loss IS NULL THEN 'No Returns'
                WHEN c.revenue_per_return_loss > 10 THEN 'High'
                WHEN c.revenue_per_return_loss < 0.1 THEN 'Low'
                ELSE 'Medium'
            END AS revenue_return_category,
            TRY_CAST(c.store_net_paid * 1000 AS BIGINT) AS store_net_paid_scaled_bigint,
            bitwise_or(CAST(c.store_txn_cnt AS BIGINT), CAST(c.web_txn_cnt AS BIGINT)) AS combined_txn_bitwise,
            (SELECT SUM(ss_net_paid) FROM store_sales WHERE ss_item_sk = c.i_item_sk) AS store_sales_lifetime,
            IF(c.store_txn_cnt > 0 AND c.web_txn_cnt = 0, 'StoreOnly', 'MixedOrWeb') AS sales_channel_flag
        FROM combined c
        WHERE
            (c.product_signature NOT LIKE '%Test%')
            AND (c.store_net_paid + c.web_net_paid + c.catalog_net_paid) > 0
            AND ((c.store_txn_cnt + c.web_txn_cnt + c.catalog_txn_cnt) % 2 = 0 OR c.total_return_loss IS NULL)
    )
SELECT *
FROM final
ORDER BY yearly_rank ASC, revenue_per_return_loss DESC
LIMIT 100
