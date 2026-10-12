WITH
sales_by_channel AS (
    SELECT
        d.d_date AS sales_date,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sale_txn_count
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
    UNION ALL
    SELECT
        d.d_date AS sales_date,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sale_txn_count
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
    UNION ALL
    SELECT
        d.d_date AS sales_date,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sale_txn_count
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
returns_by_channel AS (
    SELECT
        d.d_date AS return_date,
        'store' AS channel,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_txn_count
    FROM store_returns sr
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
    UNION ALL
    SELECT
        d.d_date AS return_date,
        'catalog' AS channel,
        SUM(cr.cr_return_amt_inc_tax) AS total_returns,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_txn_count
    FROM catalog_returns cr
    LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
    UNION ALL
    SELECT
        d.d_date AS return_date,
        'web' AS channel,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_txn_count
    FROM web_returns wr
    LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
promoted_items AS (
    SELECT
        p.p_item_sk,
        p.p_promo_id,
        CASE
            WHEN p.p_start_date_sk > p.p_end_date_sk THEN NULL
            ELSE p.p_discount_active
        END AS discount_active,
        CAST(NULLIF(p.p_cost, 0) AS double) AS promo_cost
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
top_items AS (
    SELECT
        channel,
        sales_date,
        i.i_item_sk,
        i.i_product_name,
        ROW_NUMBER() OVER (PARTITION BY channel, sales_date ORDER BY SUM(s.total_sales) DESC) AS rn
    FROM (
        SELECT
            'store' AS channel,
            d.d_date AS sales_date,
            ss.ss_item_sk AS i_item_sk,
            SUM(ss.ss_net_paid) AS total_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date, ss.ss_item_sk
        UNION ALL
        SELECT
            'catalog' AS channel,
            d.d_date AS sales_date,
            cs.cs_item_sk AS i_item_sk,
            SUM(cs.cs_net_paid) AS total_sales
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date, cs.cs_item_sk
        UNION ALL
        SELECT
            'web' AS channel,
            d.d_date AS sales_date,
            ws.ws_item_sk AS i_item_sk,
            SUM(ws.ws_net_paid) AS total_sales
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date, ws.ws_item_sk
    ) s
    JOIN item i ON s.i_item_sk = i.i_item_sk
    GROUP BY channel, sales_date, i.i_item_sk, i.i_product_name
),
final AS (
    SELECT
        COALESCE(s.sales_date, r.return_date) AS activity_date,
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0) AS net_profit,
        COALESCE(s.avg_discount, 0) AS avg_discount,
        COALESCE(s.sale_txn_count, 0) AS sale_txn_count,
        COALESCE(r.return_txn_count, 0) AS return_txn_count,
        CONCAT('Channel:', COALESCE(s.channel, r.channel), ' Date:', CAST(COALESCE(s.sales_date, r.return_date) AS varchar)) AS description,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM promoted_items pi
                WHERE pi.p_item_sk = ti.i_item_sk
                  AND pi.discount_active IS NOT NULL
            ) THEN 'Y'
            ELSE 'N'
        END AS promoted_item_flag,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(s.channel, r.channel) ORDER BY (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) DESC) AS profit_rank,
        COALESCE(ti.i_product_name, 'UNKNOWN') AS top_product_name
    FROM sales_by_channel s
    FULL OUTER JOIN returns_by_channel r
        ON s.sales_date = r.return_date AND s.channel = r.channel
    LEFT JOIN (
        SELECT channel, sales_date, i_item_sk, i_product_name, rn
        FROM top_items
        WHERE rn = 1
    ) ti
        ON ti.channel = COALESCE(s.channel, r.channel)
       AND ti.sales_date = COALESCE(s.sales_date, r.return_date)
    WHERE
        (COALESCE(s.total_sales, 0) > 0 OR COALESCE(r.total_returns, 0) > 0)
        AND COALESCE(s.avg_discount, 0) IS NOT NULL
        AND NOT (COALESCE(s.total_sales, 0) = 0 AND COALESCE(r.total_returns, 0) = 0)
)
SELECT *
FROM final
WHERE profit_rank <= 10
ORDER BY profit_rank, activity_date DESC
LIMIT 100
