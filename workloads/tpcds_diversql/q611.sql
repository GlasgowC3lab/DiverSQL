WITH
    ss_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_time_sk,
            SUM(ss_ext_sales_price) AS store_sales_total
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ss_sold_time_sk IS NOT NULL
        GROUP BY ss_store_sk, ss_sold_time_sk
    ),
    joined AS (
        SELECT
            s.s_store_name               AS store_name,
            s.s_state                    AS state,
            cp.cp_department             AS department,
            r.r_reason_desc              AS reason_desc,
            cd.cd_gender                 AS gender,
            w.w_zip                      AS zip,
            ss_agg.store_sales_total    AS store_sales_total,
            cs.cs_ext_sales_price        AS cs_ext_sales_price,
            cs.cs_net_profit             AS cs_net_profit,
            cr.cr_return_amount          AS cr_return_amount,
            t_c.t_hour                   AS sale_hour
        FROM ss_agg
        JOIN store s               ON ss_agg.ss_store_sk = s.s_store_sk
        JOIN time_dim t_s          ON ss_agg.ss_sold_time_sk = t_s.t_time_sk
        JOIN catalog_sales cs      ON cs.cs_sold_time_sk = t_s.t_time_sk
        JOIN time_dim t_c          ON cs.cs_sold_time_sk = t_c.t_time_sk
        JOIN customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr    ON cr.cr_item_sk = cs.cs_item_sk
                                   AND cr.cr_order_number = cs.cs_order_number
        JOIN reason r              ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim t_r          ON cr.cr_returned_time_sk = t_r.t_time_sk
        LEFT JOIN web_page wp      ON wp.wp_customer_sk = c.c_customer_sk
        WHERE s.s_state = 'CA'
          AND w.w_zip = '64593'
          AND r.r_reason_desc = 'Defective'
          AND t_c.t_hour BETWEEN 8 AND 12
          AND cd.cd_gender = 'M'
    ),
    agg_all AS (
        SELECT
            store_name,
            state,
            department,
            reason_desc,
            gender,
            zip,
            SUM(store_sales_total)          AS total_store_sales,
            SUM(cs_ext_sales_price)          AS total_catalog_sales,
            SUM(cr_return_amount)            AS total_return_amount,
            SUM(cs_net_profit)               AS total_net_profit,
            CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
            CASE WHEN SUM(store_sales_total) > (
                SELECT AVG(cs2.cs_ext_sales_price)
                FROM catalog_sales cs2
                WHERE cs2.cs_sold_date_sk BETWEEN 2450000 AND 2452000
            ) THEN true ELSE false END               AS above_avg_store_sales
        FROM joined
        GROUP BY store_name, state, department, reason_desc, gender, zip
    )
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_store_sales DESC) AS state_store_rank
FROM agg_all
ORDER BY state, state_store_rank
