WITH sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_net_paid) AS total_sales,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_fy_year = 2021
      AND d_sales.d_qoy = 1
    GROUP BY i.i_category
),
returns_agg AS (
    SELECT i.i_category AS category,
           SUM(cr.cr_return_amount) AS total_returns,
           SUM(cr.cr_fee) AS total_return_fee,
           COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_fy_year = 2021
      AND d_ret.d_qoy = 1
    GROUP BY i.i_category
),
combined AS (
    SELECT s.category,
           s.total_sales,
           r.total_returns,
           (r.total_returns / s.total_sales) AS return_rate,
           (s.total_discount / s.sales_cnt) AS avg_discount,
           (r.total_return_fee / r.returns_cnt) AS avg_return_fee
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.category = r.category
    WHERE s.total_sales > 10000
)
SELECT category,
       total_sales,
       total_returns,
       return_rate,
       avg_discount,
       avg_return_fee,
       RANK() OVER (ORDER BY return_rate DESC) AS category_rank
FROM combined
ORDER BY category_rank
LIMIT 10
