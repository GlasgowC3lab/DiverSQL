WITH site_open_metrics AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_tax_percentage,
        ws.web_gmt_offset,
        od.d_fy_quarter_seq AS open_fy_quarter,
        od.d_year AS open_year,
        od.d_date AS open_date,
        cd.d_fy_quarter_seq AS close_fy_quarter,
        cd.d_year AS close_year,
        cd.d_date AS close_date
    FROM web_site ws
    JOIN date_dim od
        ON ws.web_open_date_sk = od.d_date_sk
    JOIN date_dim cd
        ON ws.web_close_date_sk = cd.d_date_sk
    WHERE od.d_holiday = 'Y'
      AND cd.d_holiday = 'N'
),

quarterly_agg AS (
    SELECT
        open_fy_quarter,
        open_year,
        COUNT(*) AS num_sites,
        AVG(web_tax_percentage) AS avg_tax_pct,
        MAX(web_gmt_offset) AS max_gmt_offset,
        approx_percentile(web_tax_percentage, 0.5) AS median_tax_pct,
        array_join(array_agg(web_name ORDER BY web_tax_percentage DESC), ', ') AS top_sites_by_tax
    FROM site_open_metrics
    WHERE web_tax_percentage > 0
    GROUP BY open_fy_quarter, open_year
)

SELECT
    open_fy_quarter,
    open_year,
    num_sites,
    avg_tax_pct,
    max_gmt_offset,
    median_tax_pct,
    top_sites_by_tax,
    RANK() OVER (ORDER BY avg_tax_pct DESC) AS tax_pct_rank
FROM quarterly_agg
ORDER BY open_fy_quarter, open_year
