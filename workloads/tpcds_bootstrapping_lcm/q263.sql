WITH created_stats AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           AVG(wp_char_count) AS avg_created_char_count
    FROM web_page
    GROUP BY wp_creation_date_sk
), accessed_stats AS (
    SELECT wp_access_date_sk AS d_date_sk,
           AVG(wp_char_count) AS avg_accessed_char_count
    FROM web_page
    GROUP BY wp_access_date_sk
), aggregated AS (
    SELECT
        s.s_division_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        cs.avg_created_char_count,
        acc.avg_accessed_char_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN created_stats cs
        ON cs.d_date_sk = d.d_date_sk
    LEFT JOIN accessed_stats acc
        ON acc.d_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY s.s_division_id, d.d_year, d.d_month_seq, cs.avg_created_char_count, acc.avg_accessed_char_count
)
SELECT
    s_division_id,
    d_year,
    d_month_seq,
    total_return_amount,
    total_net_loss,
    avg_created_char_count,
    avg_accessed_char_count,
    RANK() OVER (PARTITION BY s_division_id ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
