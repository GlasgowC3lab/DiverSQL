WITH us_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        NULL AS store_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS source
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        NULL,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_bill_customer_sk,
        'web'
    FROM web_sales ws
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_customer_sk,
        'store'
    FROM store_sales ss
),
us_returns AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_item_sk AS item_sk,
        NULL AS store_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        NULL AS customer_sk,
        'catalog' AS source
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        NULL,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        NULL,
        'web'
    FROM web_returns wr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_customer_sk,
        'store'
    FROM store_returns sr
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.source,
        COALESCE(s.store_sk, -1) AS store_sk,
        SUM(s.quantity) FILTER (WHERE s.quantity > 0) AS total_quantity,
        SUM(s.net_paid) FILTER (WHERE s.net_paid >= 0) AS total_sales,
        COUNT(DISTINCT s.customer_sk) FILTER (WHERE s.customer_sk IS NOT NULL) AS distinct_customers,
        MAX(i.i_item_desc) AS any_item_desc,
        MIN(i.i_color) AS any_item_color
    FROM us_sales s
    LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.source, COALESCE(s.store_sk, -1)
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.source,
        COALESCE(r.store_sk, -1) AS store_sk,
        SUM(r.return_quantity) FILTER (WHERE r.return_quantity > 0) AS total_return_qty,
        SUM(r.return_amount) FILTER (WHERE r.return_amount >= 0) AS total_return_amount
    FROM us_returns r
    LEFT JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, r.source, COALESCE(r.store_sk, -1)
),
combined AS (
    SELECT
        COALESCE(sa.d_year, ra.d_year) AS d_year,
        COALESCE(sa.d_month_seq, ra.d_month_seq) AS d_month_seq,
        COALESCE(sa.source, ra.source) AS source,
        COALESCE(sa.store_sk, ra.store_sk) AS store_sk,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.distinct_customers, 0) AS distinct_customers,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amount, 0)) AS net_sales,
        CASE WHEN (COALESCE(sa.d_month_seq, ra.d_month_seq) % 3) = 0 THEN true ELSE false END AS is_quarter_end,
        (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amount, 0)) / NULLIF(COALESCE(ra.total_return_amount, 0), 0) AS net_to_return_ratio,
        concat_ws('|',
                  CAST(COALESCE(sa.d_year, ra.d_year) AS varchar),
                  CAST(COALESCE(sa.d_month_seq, ra.d_month_seq) AS varchar),
                  COALESCE(sa.source, ra.source),
                  COALESCE(s.s_store_name, 'UNKNOWN')
                 ) AS composite_key,
        regexp_replace(COALESCE(s.s_store_name, ''), '[0-9]', '') AS store_name_alpha
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.d_year = ra.d_year
        AND sa.d_month_seq = ra.d_month_seq
        AND sa.source = ra.source
        AND sa.store_sk = ra.store_sk
    LEFT JOIN store s ON s.s_store_sk = COALESCE(sa.store_sk, ra.store_sk)
),
ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.source ORDER BY c.net_sales DESC) AS sales_rank,
        LAG(c.net_sales) OVER (PARTITION BY c.source, c.store_sk ORDER BY c.d_year, c.d_month_seq) AS prev_net_sales,
        CASE
            WHEN LAG(c.net_sales) OVER (PARTITION BY c.source, c.store_sk ORDER BY c.d_year, c.d_month_seq) IS NULL THEN NULL
            WHEN LAG(c.net_sales) OVER (PARTITION BY c.source, c.store_sk ORDER BY c.d_year, c.d_month_seq) = 0 THEN NULL
            ELSE ((c.net_sales - LAG(c.net_sales) OVER (PARTITION BY c.source, c.store_sk ORDER BY c.d_year, c.d_month_seq))
                  / LAG(c.net_sales) OVER (PARTITION BY c.source, c.store_sk ORDER BY c.d_year, c.d_month_seq)) * 100
        END AS pct_change_vs_prev_month,
        (SELECT MAX(c2.net_sales) FROM combined c2 WHERE c2.source = c.source) AS max_source_net_sales
    FROM combined c
),
top_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        SUM(us.quantity) AS total_quantity_sold,
        SUM(us.net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(us.net_paid) DESC) AS rank_in_category,
        CASE WHEN lower(i.i_item_desc) LIKE '%special%' THEN 'YES' ELSE 'NO' END AS is_special_item,
        (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS store_sales_txn_cnt,
        (SELECT MAX(ss2.ss_net_paid) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS max_store_net_paid
    FROM us_sales us
    JOIN item i ON us.item_sk = i.i_item_sk
    WHERE us.source = 'store'
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
    HAVING SUM(us.net_paid) > (
        SELECT approx_percentile(us2.net_paid, 0.5)
        FROM us_sales us2
        WHERE us2.source = 'store'
    )
),
final_result AS (
    SELECT
        r.d_year,
        r.d_month_seq,
        r.source,
        r.store_sk,
        r.net_sales,
        r.sales_rank,
        r.prev_net_sales,
        r.pct_change_vs_prev_month,
        r.is_quarter_end,
        r.composite_key,
        (SELECT COUNT(*) FROM store s2 WHERE s2.s_store_sk = r.store_sk) AS store_lookup_count,
        r.max_source_net_sales
    FROM ranked r
    WHERE r.sales_rank <= 5
    UNION ALL
    SELECT
        NULL,
        NULL,
        'top_items',
        NULL,
        ti.total_sales,
        ti.rank_in_category,
        NULL,
        NULL,
        NULL,
        concat_ws('|', CAST(ti.i_item_sk AS varchar), ti.i_brand, ti.i_category, ti.is_special_item, CAST(ti.store_sales_txn_cnt AS varchar)),
        NULL,
        NULL
    FROM top_items ti
    WHERE ti.rank_in_category <= 3
)
SELECT *
FROM final_result
ORDER BY source, sales_rank NULLS LAST, d_year, d_month_seq
