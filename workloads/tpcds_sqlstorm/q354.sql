WITH
sales_union AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        d.d_year AS year,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        ss.ss_net_profit,
        ss.ss_net_paid,
        'store'
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        d.d_year,
        cs.cs_net_profit,
        cs.cs_net_paid,
        'catalog'
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
returns_union AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_date_sk AS return_date_sk,
        d.d_year AS year,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        d.d_year,
        sr.sr_net_loss,
        'store'
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        d.d_year,
        cr.cr_net_loss,
        'catalog'
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
),
ranked_items AS (
    SELECT
        a.item_sk,
        a.total_profit,
        a.total_paid,
        a.txn_count,
        COALESCE(r.total_loss, 0) AS total_loss,
        a.total_profit - COALESCE(r.total_loss, 0) AS net_gain,
        RANK() OVER (ORDER BY (a.total_profit - COALESCE(r.total_loss, 0)) DESC) AS profit_rank
    FROM (
        SELECT
            item_sk,
            SUM(net_profit) AS total_profit,
            SUM(net_paid) AS total_paid,
            COUNT(*) AS txn_count
        FROM sales_union
        WHERE year = 2001
        GROUP BY item_sk
    ) a
    LEFT JOIN (
        SELECT
            item_sk,
            SUM(net_loss) AS total_loss
        FROM returns_union
        WHERE year = 2001
        GROUP BY item_sk
    ) r
    ON a.item_sk = r.item_sk
),
top_items AS (
    SELECT
        ri.item_sk,
        ri.total_profit,
        ri.total_paid,
        ri.txn_count,
        ri.total_loss,
        ri.net_gain,
        ri.profit_rank,
        2001 AS year
    FROM ranked_items ri
    WHERE ri.profit_rank <= 10
)

SELECT
    i.i_item_id,
    i.i_product_name,
    ti.year,
    ti.total_profit,
    ti.total_paid,
    ti.txn_count,
    ti.total_loss,
    ti.net_gain,
    ti.profit_rank,
    CONCAT(i.i_item_id, '-', CAST(ti.year AS VARCHAR)) AS report_key,
    COALESCE(
        (SELECT SUM(net_profit)
         FROM sales_union su2
         WHERE su2.item_sk = ti.item_sk AND su2.year = 2000), 0) AS prev_year_profit,
    (ti.net_gain - COALESCE(
        (SELECT SUM(net_profit)
         FROM sales_union su2
         WHERE su2.item_sk = ti.item_sk AND su2.year = 2000), 0)) AS profit_change_vs_2000,
    SUM(ti.total_profit) OVER (ORDER BY ti.profit_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    CASE WHEN ti.total_loss > 0 THEN 'LOSS_PRESENT' ELSE 'NO_LOSS' END AS loss_flag,
    p.p_promo_name
FROM top_items ti
JOIN item i ON ti.item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        p_item_sk,
        MAX(p_promo_name) AS p_promo_name
    FROM promotion
    WHERE p_start_date_sk <= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
      AND p_end_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY p_item_sk
) p ON i.i_item_sk = p.p_item_sk
WHERE COALESCE(i.i_product_name, '') <> ''
UNION ALL
SELECT
    'TOTAL' AS i_item_id,
    NULL AS i_product_name,
    NULL AS year,
    SUM(ti.total_profit) AS total_profit,
    SUM(ti.total_paid) AS total_paid,
    SUM(ti.txn_count) AS txn_count,
    SUM(ti.total_loss) AS total_loss,
    SUM(ti.net_gain) AS net_gain,
    NULL AS profit_rank,
    NULL AS report_key,
    NULL AS prev_year_profit,
    NULL AS profit_change_vs_2000,
    SUM(ti.total_profit) AS cumulative_profit,
    CASE WHEN SUM(ti.total_loss) > 0 THEN 'LOSS_PRESENT' ELSE 'NO_LOSS' END AS loss_flag,
    NULL AS p_promo_name
FROM top_items ti
ORDER BY profit_rank NULLS LAST, i_item_id
