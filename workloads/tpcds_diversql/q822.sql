WITH
    joined_data AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cp.cp_catalog_number,
            cp.cp_catalog_page_number,
            sm.sm_type,
            r.r_reason_desc,
            cd.cd_gender,
            td.t_hour,
            td.t_am_pm,
            ss.ss_ext_sales_price AS ss_ext_sales_price,
            ss.ss_net_profit AS ss_net_profit
        FROM catalog_sales cs
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN ship_mode sm_ret
            ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
        LEFT JOIN catalog_page cp_ret
            ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
        LEFT JOIN customer_demographics cd_ret
            ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
        JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
            AND ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE cp.cp_catalog_number = 15
          AND td.t_hour IN (9, 10, 13)
          AND cd.cd_gender = 'F'
    ),
    computed_set AS (
        SELECT 1 AS val UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    cross_joined AS (
        SELECT jd.*, cs.val AS extra_flag
        FROM joined_data jd
        CROSS JOIN computed_set cs
    ),
    union_set AS (
        SELECT jd.cs_order_number AS order_key,
               jd.cs_ext_sales_price AS amount,
               'sales' AS src
        FROM joined_data jd
        UNION
        SELECT jd.cs_order_number AS order_key,
               jd.cr_return_amount AS amount,
               'return' AS src
        FROM joined_data jd
        WHERE jd.cr_return_amount IS NOT NULL
    ),
    except_set AS (
        SELECT cs_order_number AS order_key FROM catalog_sales
        EXCEPT
        SELECT cr_order_number AS order_key FROM catalog_returns
    ),
    final AS (
        SELECT
            u.order_key,
            COUNT(*) AS cnt,
            SUM(u.amount) AS total_amount,
            MIN(u.amount) AS min_amount,
            MAX(u.amount) AS max_amount
        FROM union_set u
        WHERE u.order_key NOT IN (SELECT order_key FROM except_set)
        GROUP BY u.order_key
    )
SELECT
    f.order_key,
    f.cnt,
    f.total_amount,
    f.min_amount,
    f.max_amount,
    cj.extra_flag,
    cj.t_hour,
    cj.t_am_pm,
    cj.ss_ext_sales_price,
    cj.ss_net_profit,
    cj.sm_type,
    cj.r_reason_desc
FROM final f
JOIN cross_joined cj
    ON f.order_key = cj.cs_order_number
ORDER BY f.total_amount DESC
LIMIT 100
