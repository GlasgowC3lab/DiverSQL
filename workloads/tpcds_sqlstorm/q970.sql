WITH all_sales AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ticket_number AS order_number,
        'store' AS src
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_order_number,
        'catalog'
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_order_number,
        'web'
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        s.customer_sk,
        d.d_year,
        d.d_quarter_name,
        d.d_quarter_seq,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid) AS total_net_paid,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        COUNT(*) AS sales_rows,
        array_join(array_distinct(array_agg(s.src)), ',') AS sources_used
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY
        s.customer_sk,
        d.d_year,
        d.d_quarter_name,
        d.d_quarter_seq
),
all_returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS qty,
        'store' AS src
    FROM store_returns sr
    UNION ALL
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_returned_date_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        'catalog'
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        'web'
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        r.customer_sk,
        d.d_year,
        d.d_quarter_name,
        SUM(r.net_loss) AS total_net_loss,
        SUM(r.qty) AS total_return_qty,
        COUNT(*) AS return_rows,
        MAX(r.net_loss) AS max_net_loss
    FROM all_returns r
    LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY
        r.customer_sk,
        d.d_year,
        d.d_quarter_name
),
customer_demo AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
        CASE
            WHEN cd.cd_credit_rating IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_credit_rating IN ('A','B','C') THEN 'LOW'
            WHEN cd.cd_credit_rating IN ('D','E') THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS risk_category,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_dep_count,0) AS dependent_count,
        COALESCE(cd.cd_dep_employed_count,0) AS employed_deps,
        COALESCE(cd.cd_dep_college_count,0) AS college_deps
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_agg AS (
    SELECT
        s.customer_sk,
        cd.full_name,
        cd.risk_category,
        s.d_year,
        s.d_quarter_name,
        s.d_quarter_seq,
        s.total_net_profit,
        s.total_net_paid,
        s.distinct_orders,
        s.sales_rows,
        s.sources_used,
        COALESCE(r.total_net_loss,0) AS total_net_loss,
        COALESCE(r.total_return_qty,0) AS total_return_qty,
        (s.total_net_profit - COALESCE(r.total_net_loss,0)) AS net_profit_adj,
        CASE
            WHEN (s.total_net_profit + COALESCE(r.total_net_loss,0)) = 0 THEN NULL
            ELSE (s.total_net_profit - COALESCE(r.total_net_loss,0)) / (s.total_net_profit + COALESCE(r.total_net_loss,0))
        END AS profit_loss_ratio,
        RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY s.customer_sk ORDER BY s.d_year DESC, s.d_quarter_seq DESC) AS recent_quarter_seq,
        LAG(s.total_net_profit) OVER (PARTITION BY s.customer_sk ORDER BY s.d_year, s.d_quarter_seq) AS prior_quarter_profit,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM sales_agg s2
                WHERE s2.d_year = s.d_year
                  AND s2.d_quarter_name = s.d_quarter_name
                  AND s2.total_net_profit > s.total_net_profit
            ) THEN 1
            ELSE 0
        END AS higher_profit_exists,
        REPLACE(
            CONCAT(
                COALESCE(cd.full_name,'UNKNOWN'),
                '_',
                s.d_quarter_name,
                '_',
                CAST(s.d_year AS VARCHAR)
            ),
            ' ',
            '-'
        ) AS dim_key,
        CASE
            WHEN s.sources_used IS NOT DISTINCT FROM 'store' THEN 'ONLY_STORE'
            WHEN lower(s.sources_used) LIKE '%catalog%' THEN 'HAS_CATALOG'
            ELSE 'MIXED'
        END AS source_category,
        date_trunc('quarter', date_parse(CONCAT(CAST(s.d_year AS VARCHAR), '-01-01'), '%Y-%m-%d')) AS quarter_start_date
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.customer_sk = r.customer_sk
        AND s.d_year = r.d_year
        AND s.d_quarter_name = r.d_quarter_name
    LEFT JOIN customer_demo cd ON s.customer_sk = cd.c_customer_sk
),
missing_quarts AS (
    SELECT
        dist.d_year,
        dist.d_quarter_name,
        dist.d_quarter_seq
    FROM (
        SELECT DISTINCT d_year, d_quarter_name, d_quarter_seq
        FROM date_dim
    ) dist
    WHERE NOT EXISTS (
        SELECT 1
        FROM final_agg fa
        WHERE fa.d_year = dist.d_year
          AND fa.d_quarter_name = dist.d_quarter_name
    )
)
SELECT *
FROM final_agg
WHERE profit_loss_ratio IS NOT NULL
  AND (risk_category = 'HIGH' OR risk_category = 'UNKNOWN')
UNION ALL
SELECT
    NULL AS customer_sk,
    NULL AS full_name,
    NULL AS risk_category,
    mq.d_year,
    mq.d_quarter_name,
    mq.d_quarter_seq,
    0 AS total_net_profit,
    0 AS total_net_paid,
    0 AS distinct_orders,
    0 AS sales_rows,
    NULL AS sources_used,
    0 AS total_net_loss,
    0 AS total_return_qty,
    0 AS net_profit_adj,
    NULL AS profit_loss_ratio,
    NULL AS profit_rank,
    NULL AS recent_quarter_seq,
    NULL AS prior_quarter_profit,
    0 AS higher_profit_exists,
    CONCAT('MISSING_', mq.d_quarter_name, '_', CAST(mq.d_year AS VARCHAR)) AS dim_key,
    'NO_DATA' AS source_category,
    date_trunc('quarter', date_parse(CONCAT(CAST(mq.d_year AS VARCHAR), '-01-01'), '%Y-%m-%d')) AS quarter_start_date
FROM missing_quarts mq
ORDER BY profit_loss_ratio DESC NULLS LAST, d_year, d_quarter_seq
