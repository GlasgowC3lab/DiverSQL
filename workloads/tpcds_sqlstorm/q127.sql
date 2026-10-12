WITH sales_data AS (
    SELECT
        s.s_state AS region,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        cc.cc_state AS region,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        'Online' AS region,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
    region,
    d_year,
    i_category,
    i_brand,
    i_item_id,
    total_quantity,
    total_profit,
    rn
FROM (
    SELECT
        region,
        d_year,
        i_category,
        i_brand,
        i_item_id,
        SUM(quantity) AS total_quantity,
        SUM(profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY region, d_year ORDER BY SUM(profit) DESC) AS rn
    FROM sales_data
    GROUP BY region, d_year, i_category, i_brand, i_item_id
) ranked
WHERE rn <= 10
ORDER BY region, d_year, total_profit DESC
