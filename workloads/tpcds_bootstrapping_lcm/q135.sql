WITH catalog_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        SUM(cr_net_loss) AS cat_net_loss,
        SUM(cr_return_amount) AS cat_return_amount,
        COUNT(*) AS cat_return_cnt,
        AVG(cr_return_quantity) AS cat_avg_qty
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
web_agg AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_return_amt) AS web_return_amount,
        COUNT(*) AS web_return_cnt,
        AVG(wr_return_quantity) AS web_avg_qty
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_division_name,
    ws.web_name,
    ca.cat_return_cnt,
    ca.cat_net_loss,
    ca.cat_return_amount,
    ca.cat_avg_qty,
    wa.web_return_cnt,
    wa.web_net_loss,
    wa.web_return_amount,
    wa.web_avg_qty,
    (ca.cat_net_loss + wa.web_net_loss) AS total_net_loss,
    (ca.cat_return_amount + wa.web_return_amount) AS total_return_amount
FROM date_dim d
JOIN catalog_agg ca ON ca.date_sk = d.d_date_sk
JOIN web_agg wa ON wa.date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY d.d_year, d.d_quarter_name, s.s_division_name
LIMIT 100
