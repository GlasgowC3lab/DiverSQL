WITH returns_by_date AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        SUM(cr.cr_return_amount)        AS cat_return_amt,
        SUM(cr.cr_net_loss)            AS cat_net_loss,
        SUM(cr.cr_return_quantity)     AS cat_return_qty,
        SUM(wr.wr_return_amt)          AS web_return_amt,
        SUM(wr.wr_net_loss)            AS web_net_loss,
        SUM(wr.wr_return_quantity)     AS web_return_qty
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.s_state,
    r.cat_return_amt,
    r.web_return_amt,
    r.cat_net_loss,
    r.web_net_loss,
    r.cat_return_amt + r.web_return_amt                      AS total_return_amt,
    r.cat_return_qty + r.web_return_qty                      AS total_return_qty,
    ROUND(
        (r.cat_return_amt + r.web_return_amt) /
        NULLIF(r.cat_return_qty + r.web_return_qty, 0), 2)   AS avg_return_per_item,
    CASE
        WHEN r.cat_return_amt > r.web_return_amt THEN 'Catalog'
        WHEN r.web_return_amt > r.cat_return_amt THEN 'Web'
        ELSE 'Equal'
    END                                                      AS dominant_source,
    ROW_NUMBER() OVER (
        PARTITION BY r.s_state
        ORDER BY (r.cat_return_amt + r.web_return_amt) DESC
    )                                                       AS rank_by_state
FROM returns_by_date r
WHERE (r.cat_return_amt + r.web_return_amt) > 10000
ORDER BY rank_by_state, r.s_state
LIMIT 100
