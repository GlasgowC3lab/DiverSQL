WITH agg_returns AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN cr_store_credit > 0 THEN cr_store_credit ELSE 0 END) AS total_store_credit
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity > 0
      AND cr_fee <= 500
      AND cr_return_tax BETWEEN 0 AND 100
      AND cr_return_ship_cost > 0
      AND cr_net_loss IS NOT NULL
    GROUP BY cr_returned_date_sk
)
,
unioned AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d.d_year,
        d.d_quarter_name,
        ar.total_return_amount,
        ar.total_return_qty,
        ar.cnt_returns,
        CASE
            WHEN ar.total_store_credit > 1000 THEN 'HIGH'
            WHEN ar.total_store_credit > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS store_credit_category
    FROM agg_returns ar
    INNER JOIN date_dim d
        ON ar.cr_returned_date_sk = d.d_date_sk
    RIGHT OUTER JOIN web_site ws
        ON d.d_date_sk = ws.web_open_date_sk
    WHERE ws.web_gmt_offset BETWEEN -8.00 AND -5.00
      AND ws.web_class = 'Unknown'
      AND d.d_current_quarter = 'Y'
      AND d.d_qoy = 2
      AND d.d_year = 2001
      AND ws.web_suite_number LIKE 'Suite %'
      AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_returned_date_sk = d.d_date_sk
              AND cr2.cr_return_amount > 10000
      )

    UNION DISTINCT

    SELECT
        ws.web_site_id,
        ws.web_name,
        d.d_year,
        d.d_quarter_name,
        ar2.total_return_amount,
        ar2.total_return_qty,
        ar2.cnt_returns,
        CASE
            WHEN ar2.total_store_credit > 500 THEN 'HIGH2'
            ELSE 'LOW2'
        END AS store_credit_category
    FROM agg_returns ar2
    INNER JOIN date_dim d
        ON ar2.cr_returned_date_sk = d.d_date_sk
    RIGHT OUTER JOIN web_site ws
        ON d.d_date_sk = ws.web_close_date_sk
    WHERE ws.web_gmt_offset = -6.00
      AND ws.web_class = 'Unknown'
      AND d.d_current_quarter = 'N'
      AND d.d_qoy = 1
      AND d.d_year = 2000
      AND ws.web_suite_number LIKE 'Suite 1%'
)
SELECT * FROM unioned
LIMIT 100
