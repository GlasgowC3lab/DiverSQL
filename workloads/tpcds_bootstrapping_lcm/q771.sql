WITH
sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_date_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returned_date_sk, d.d_year, d.d_month_seq
),
web_page_creation_agg AS (
    SELECT
        wp.wp_creation_date_sk,
        d.d_year,
        d.d_month_seq,
        SUM(wp.wp_image_count) AS total_image_count,
        SUM(wp.wp_link_count) AS total_link_count,
        SUM(wp.wp_char_count) AS total_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY wp.wp_creation_date_sk, d.d_year, d.d_month_seq
),
web_page_access_agg AS (
    SELECT
        wp.wp_access_date_sk,
        d.d_year,
        d.d_month_seq,
        SUM(wp.wp_image_count) AS access_image_count,
        SUM(wp.wp_link_count) AS access_link_count,
        SUM(wp.wp_char_count) AS access_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY wp.wp_access_date_sk, d.d_year, d.d_month_seq
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_closed_date_sk
    FROM store s
)
SELECT
    si.s_store_id,
    si.s_store_name,
    COALESCE(sa.d_year, ra.d_year, wca.d_year, waa.d_year) AS year,
    COALESCE(sa.d_month_seq, ra.d_month_seq, wca.d_month_seq, waa.d_month_seq) AS month_seq,
    COALESCE(sa.d_year, ra.d_year, wca.d_year, waa.d_year) * 100
        + COALESCE(sa.d_month_seq, ra.d_month_seq, wca.d_month_seq, waa.d_month_seq) AS period_id,
    SUM(COALESCE(sa.total_sales, 0)) AS total_sales,
    SUM(COALESCE(sa.total_profit, 0)) AS total_profit,
    CASE
        WHEN SUM(COALESCE(sa.total_sales, 0)) > 0
        THEN SUM(COALESCE(sa.total_profit, 0)) / SUM(COALESCE(sa.total_sales, 0))
        ELSE 0
    END AS profit_margin,
    SUM(COALESCE(sa.ticket_cnt, 0)) AS ticket_cnt,
    SUM(COALESCE(ra.total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(ra.total_net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(ra.return_cnt, 0)) AS return_cnt,
    SUM(COALESCE(wca.total_image_count, 0)) AS total_image_count,
    SUM(COALESCE(wca.total_link_count, 0)) AS total_link_count,
    SUM(COALESCE(wca.total_char_count, 0)) AS total_char_count,
    SUM(COALESCE(waa.access_image_count, 0)) AS access_image_count,
    SUM(COALESCE(waa.access_link_count, 0)) AS access_link_count,
    SUM(COALESCE(waa.access_char_count, 0)) AS access_char_count,
    MAX(d_closed.d_year) AS store_closed_year,
    MAX(d_closed.d_month_seq) AS store_closed_month_seq
FROM store_info si
LEFT JOIN sales_agg sa ON sa.ss_store_sk = si.s_store_sk
LEFT JOIN returns_agg ra ON ra.cr_returned_date_sk = sa.d_date_sk
LEFT JOIN web_page_creation_agg wca ON wca.wp_creation_date_sk = sa.d_date_sk
LEFT JOIN web_page_access_agg waa ON waa.wp_access_date_sk = sa.d_date_sk
LEFT JOIN date_dim d_closed ON si.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    si.s_store_id,
    si.s_store_name,
    COALESCE(sa.d_year, ra.d_year, wca.d_year, waa.d_year),
    COALESCE(sa.d_month_seq, ra.d_month_seq, wca.d_month_seq, waa.d_month_seq),
    COALESCE(sa.d_year, ra.d_year, wca.d_year, waa.d_year) * 100
        + COALESCE(sa.d_month_seq, ra.d_month_seq, wca.d_month_seq, waa.d_month_seq)
HAVING SUM(COALESCE(sa.total_sales, 0) + COALESCE(ra.total_return_amount, 0) + COALESCE(wca.total_image_count, 0)) > 0
ORDER BY year, month_seq, si.s_store_id
