WITH web_sales_sample AS (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
),
ws_agg AS (
    SELECT
        'Web Sales' AS entity_type,
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS metric
    FROM web_sales_sample ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM customer_demographics cd
          WHERE cd.cd_demo_sk = ws.ws_bill_cdemo_sk
            AND cd.cd_education_status = 'College'
      )
    GROUP BY d.d_year
),
closed_counts AS (
    SELECT
        'Closed Entity' AS entity_type,
        d.d_year AS year,
        CAST(COALESCE(s.s_cnt, 0) + COALESCE(cc.c_cnt, 0) AS decimal(10,2)) AS metric
    FROM (
        SELECT s_closed_date_sk, COUNT(*) AS s_cnt
        FROM store
        GROUP BY s_closed_date_sk
    ) s
    FULL OUTER JOIN (
        SELECT cc_closed_date_sk, COUNT(*) AS c_cnt
        FROM call_center
        GROUP BY cc_closed_date_sk
    ) cc
    ON s.s_closed_date_sk = cc.cc_closed_date_sk
    JOIN date_dim d ON d.d_date_sk = COALESCE(s.s_closed_date_sk, cc.cc_closed_date_sk)
    WHERE d.d_year = 2001
)
SELECT entity_type, year, metric
FROM ws_agg
UNION
SELECT entity_type, year, metric
FROM closed_counts
LIMIT 100
