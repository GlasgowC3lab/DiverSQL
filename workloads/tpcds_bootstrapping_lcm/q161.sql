WITH cat_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        SUM(cr_net_loss) AS cat_net_loss,
        COUNT(*) AS cat_return_cnt,
        SUM(cr_return_quantity) AS cat_qty,
        AVG(cr_return_amount) AS avg_cat_ret_amt
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
web_agg AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        SUM(wr_return_quantity) AS web_qty,
        AVG(wr_return_amt) AS avg_web_ret_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    COALESCE(cat.cat_net_loss, 0) AS cat_net_loss,
    COALESCE(web.web_net_loss, 0) AS web_net_loss,
    (COALESCE(cat.cat_net_loss, 0) + COALESCE(web.web_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN COALESCE(web.web_net_loss, 0) = 0 THEN NULL
        ELSE COALESCE(cat.cat_net_loss, 0) / COALESCE(web.web_net_loss, 0)
    END AS cat_to_web_loss_ratio,
    COALESCE(cat.cat_return_cnt, 0) AS cat_return_cnt,
    COALESCE(web.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(cat.avg_cat_ret_amt, 0) AS avg_cat_ret_amt,
    COALESCE(web.avg_web_ret_amt, 0) AS avg_web_ret_amt,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_year
        ORDER BY (COALESCE(cat.cat_net_loss, 0) + COALESCE(web.web_net_loss, 0)) DESC
    ) AS loss_rank_by_year
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN cat_agg cat
    ON cat.date_sk = d.d_date_sk
LEFT JOIN web_agg web
    ON web.date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_store_sk IS NOT NULL
ORDER BY d.d_year, loss_rank_by_year
LIMIT 100
