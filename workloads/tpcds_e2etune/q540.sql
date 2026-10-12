WITH sales AS (
    SELECT
        cp.cp_department AS department,
        i.i_category AS category,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(cs.cs_quantity) AS sales_qty
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'Morning'
    GROUP BY cp.cp_department, i.i_category, d.d_year, d.d_moy
),
returns AS (
    SELECT
        cp.cp_department AS department,
        i.i_category AS category,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cr.cr_net_loss) AS return_loss,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND t2.t_shift = 'Morning'
    GROUP BY cp.cp_department, i.i_category, d.d_year, d.d_moy
)
SELECT
    s.department,
    s.category,
    s.year,
    s.month,
    s.sales_profit,
    COALESCE(r.return_loss, 0) AS return_loss,
    s.sales_profit - COALESCE(r.return_loss, 0) AS net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.year, s.month ORDER BY s.sales_profit - COALESCE(r.return_loss, 0) DESC) AS dept_category_rank
FROM sales s
LEFT JOIN returns r
    ON s.department = r.department
   AND s.category = r.category
   AND s.year = r.year
   AND s.month = r.month
ORDER BY s.year, s.month, net_profit DESC
LIMIT 100
