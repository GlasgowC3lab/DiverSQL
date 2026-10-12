WITH catalog_agg AS (
    SELECT
        cd.cd_gender AS gender,
        'catalog' AS source,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_country = 'United States'
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY cd.cd_gender
),
web_agg AS (
    SELECT
        cd.cd_gender AS gender,
        'web' AS source,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND ws.ws_ship_date_sk BETWEEN 2452000 AND 2452500
    GROUP BY cd.cd_gender
),
combined AS (
    SELECT gender, source, total_sales FROM catalog_agg
    UNION ALL
    SELECT gender, source, total_sales FROM web_agg
)
SELECT
    gender,
    source,
    total_sales,
    rn
FROM (
    SELECT
        gender,
        source,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_sales DESC) AS rn
    FROM combined
) ranked
WHERE rn <= 2
ORDER BY gender, rn
LIMIT 100
