WITH returns_enriched AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        d.d_year,
        d.d_moy,
        d.d_date AS return_date,
        wr.wr_refunded_customer_sk,
        c.c_birth_country,
        c.c_birth_year,
        wr.wr_web_page_sk,
        wp.wp_type,
        wp.wp_creation_date_sk,
        cd.d_date AS page_creation_date
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
    WHERE d.d_year = 2022
      AND c.c_birth_country IN ('CHILE', 'MEXICO', 'FIJI')
), aggregated AS (
    SELECT
        r.c_birth_country,
        r.wp_type,
        COUNT(*) AS return_cnt,
        SUM(r.wr_net_loss) AS total_net_loss,
        AVG(r.wr_return_amt) AS avg_return_amt,
        MIN(r.return_date) AS first_return_date,
        MAX(r.return_date) AS last_return_date
    FROM returns_enriched r
    GROUP BY r.c_birth_country, r.wp_type
    HAVING SUM(r.wr_net_loss) > 1000
)
SELECT
    a.c_birth_country,
    a.wp_type,
    a.return_cnt,
    a.total_net_loss,
    a.avg_return_amt,
    a.first_return_date,
    a.last_return_date,
    RANK() OVER (PARTITION BY a.c_birth_country ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.c_birth_country, net_loss_rank
LIMIT 100
