WITH monthly_category_sales AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        w.web_state,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 2021 AND 2022
    GROUP BY i.i_category, d.d_year, d.d_month_seq, w.web_state
)
SELECT
    mcs.i_category,
    mcs.d_year,
    mcs.d_month_seq,
    mcs.web_state,
    mcs.monthly_sales,
    LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq) AS prev_month_sales,
    CASE
        WHEN LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq) IS NULL THEN 'N/A'
        WHEN mcs.monthly_sales > LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq) THEN 'Increase'
        WHEN mcs.monthly_sales < LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq) THEN 'Decrease'
        ELSE 'Flat'
    END AS sales_trend,
    ROUND(
        100.0 * (
            mcs.monthly_sales - COALESCE(LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq), 0)
        ) / NULLIF(LAG(mcs.monthly_sales) OVER (PARTITION BY mcs.i_category, mcs.web_state ORDER BY mcs.d_year, mcs.d_month_seq), 0),
        2
    ) AS pct_change
FROM monthly_category_sales mcs
ORDER BY mcs.i_category, mcs.web_state, mcs.d_year, mcs.d_month_seq
