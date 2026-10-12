WITH cr_daily AS (
    SELECT
        cr_returned_date_sk AS d_date_sk,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(cr_return_quantity) AS catalog_return_qty,
        SUM(cr_return_amount) AS catalog_return_amt
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
wr_daily AS (
    SELECT
        wr_returned_date_sk AS d_date_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_return_quantity) AS web_return_qty,
        SUM(wr_return_amt) AS web_return_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
    (COALESCE(cr.catalog_return_amt, 0) + COALESCE(wr.web_return_amt, 0)) /
        NULLIF(COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0), 0) AS avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) DESC) AS loss_rank_year
FROM date_dim d
LEFT JOIN cr_daily cr ON cr.d_date_sk = d.d_date_sk
LEFT JOIN wr_daily wr ON wr.d_date_sk = d.d_date_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year IS NOT NULL
ORDER BY total_net_loss DESC
LIMIT 100
