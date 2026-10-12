WITH sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    s.i_category,
    s.year_month,
    s.total_sales - COALESCE(r.total_return_amt, 0) AS net_sales,
    s.total_qty - COALESCE(r.total_return_qty, 0) AS net_qty,
    s.total_discount,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    CASE WHEN s.total_sales > 0
         THEN (s.total_profit - COALESCE(r.total_return_loss, 0)) / s.total_sales
         ELSE 0
    END AS profit_margin,
    RANK() OVER (PARTITION BY s.year_month ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.year_month = r.year_month
ORDER BY s.year_month, net_sales DESC
LIMIT 100
