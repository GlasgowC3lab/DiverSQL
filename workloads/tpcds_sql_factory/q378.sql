WITH dept_sales AS (
    SELECT
        cp.cp_department,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department
),
dept_returns AS (
    SELECT
        cp.cp_department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department
)
SELECT
    ds.cp_department,
    ds.total_sales,
    ds.total_profit,
    dr.total_return_amount,
    dr.total_loss,
    (ds.total_sales - dr.total_return_amount) AS net_sales,
    (ds.total_profit - dr.total_loss) AS net_contribution,
    CASE
        WHEN (ds.total_profit - dr.total_loss) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS contribution_sign,
    DENSE_RANK() OVER (ORDER BY (ds.total_profit - dr.total_loss) DESC) AS profit_contrib_rank
FROM dept_sales ds
LEFT JOIN dept_returns dr
    ON ds.cp_department = dr.cp_department
ORDER BY profit_contrib_rank
LIMIT 10
