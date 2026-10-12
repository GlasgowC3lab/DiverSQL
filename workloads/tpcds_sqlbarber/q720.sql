SELECT
    ws.web_site_id,
    ws.web_name,
    dd.d_date,
    CASE WHEN dd.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    ws.web_gmt_offset * 60 AS offset_minutes,
    dd.d_year - ws.web_open_date_sk AS year_diff,
    CASE 
        WHEN ws.web_tax_percentage > 0.11 THEN 'HighTax'
        WHEN ws.web_tax_percentage > 0.00 THEN 'MediumTax'
        ELSE 'LowTax'
    END AS tax_category,
    ws.web_gmt_offset + ws.web_tax_percentage AS combined_offset_tax
FROM web_site ws
JOIN date_dim dd
    ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_year = 1905 AND ws.web_tax_percentage > 0.09
