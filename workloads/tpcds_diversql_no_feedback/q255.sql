WITH high_fee_returns AS (
    SELECT
        d.d_date AS return_date,
        t.t_hour AS return_hour,
        p.cp_department AS department,
        SUM(r.cr_return_amount) AS total_return_amount,
        CASE WHEN r.cr_fee > 30 THEN 'High' ELSE 'Low' END AS fee_category
    FROM catalog_returns r
    JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON r.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page p ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
    WHERE r.cr_return_amount > 100
      AND r.cr_fee > 20
      AND d.d_week_seq BETWEEN 5 AND 15
    GROUP BY
        d.d_date,
        t.t_hour,
        p.cp_department,
        CASE WHEN r.cr_fee > 30 THEN 'High' ELSE 'Low' END
),
low_fee_returns AS (
    SELECT
        d.d_date AS return_date,
        t.t_hour AS return_hour,
        p.cp_department AS department,
        SUM(r.cr_return_amount) AS total_return_amount,
        CASE WHEN r.cr_fee > 30 THEN 'High' ELSE 'Low' END AS fee_category
    FROM catalog_returns r
    JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON r.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page p ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
    WHERE r.cr_return_amount <= 100
      AND r.cr_fee <= 20
      AND d.d_week_seq NOT BETWEEN 5 AND 15
    GROUP BY
        d.d_date,
        t.t_hour,
        p.cp_department,
        CASE WHEN r.cr_fee > 30 THEN 'High' ELSE 'Low' END
)
SELECT * FROM high_fee_returns
UNION ALL
SELECT * FROM low_fee_returns
LIMIT 100
