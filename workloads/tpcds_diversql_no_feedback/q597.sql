WITH joined_data AS (
    SELECT
        cc.cc_name,
        cp.cp_department,
        cd.cd_gender,
        hd.hd_vehicle_count,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sales_price,
        cr.cr_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        cc.cc_company_name,
        cc.cc_zip,
        cc.cc_rec_start_date,
        cp.cp_type
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cc.cc_company_name = 'able'
        AND cc.cc_zip = '70411'
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
        AND cp.cp_type = 'monthly'
        AND cd.cd_gender = 'F'
        AND hd.hd_vehicle_count >= 2
        AND r.r_reason_desc LIKE '%damaged%'
),
agg_data AS (
    SELECT
        cc_name,
        cp_department,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        COUNT(DISTINCT r_reason_id) AS distinct_reasons,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_quantity) AS avg_quantity,
        MIN(cs_sales_price) AS min_sales_price,
        MAX(cs_sales_price) AS max_sales_price
    FROM joined_data
    GROUP BY
        cc_name,
        cp_department,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
)
SELECT
    cc_name,
    cp_department,
    vehicle_category,
    distinct_orders,
    distinct_reasons,
    total_net_profit,
    avg_quantity,
    min_sales_price,
    max_sales_price,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_data
ORDER BY total_net_profit DESC
LIMIT 100
