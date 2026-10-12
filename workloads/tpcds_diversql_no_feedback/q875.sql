WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        td.t_hour,
        cs.cs_net_profit,
        cr.cr_net_loss,
        ss.ss_quantity AS store_quantity,
        ws.ws_quantity AS web_quantity,
        s.s_store_name,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        r.r_reason_desc,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE i.i_brand = 'Brand#12'
      AND cd.cd_gender = 'M'
      AND w.w_zip = '64593'
      AND td.t_hour BETWEEN 8 AND 12
      AND c.c_birth_year BETWEEN 1960 AND 1970
),
agg AS (
    SELECT
        i_brand,
        i_category,
        cd_gender,
        SUM(cs_net_profit) AS total_profit,
        SUM(cr_net_loss) AS total_loss,
        COUNT(DISTINCT cs_order_number) AS orders
    FROM base
    GROUP BY GROUPING SETS (
        (i_brand, i_category, cd_gender),
        (i_brand, cd_gender),
        (i_brand)
    )
)
SELECT *
FROM (
    SELECT
        i_brand,
        i_category,
        cd_gender,
        total_profit,
        total_loss,
        orders,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS profit_rank,
        LAG(total_profit) OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS prev_profit,
        SUM(total_profit) OVER (PARTITION BY i_brand ORDER BY total_profit DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit
    FROM agg
) a
WHERE total_profit > 0
UNION DISTINCT
SELECT
    i_brand,
    i_category,
    cd_gender,
    total_profit,
    total_loss,
    orders,
    profit_rank,
    prev_profit,
    running_profit
FROM (
    SELECT
        i_brand,
        i_category,
        cd_gender,
        total_profit,
        total_loss,
        orders,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS profit_rank,
        LAG(total_profit) OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS prev_profit,
        SUM(total_profit) OVER (PARTITION BY i_brand ORDER BY total_profit DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit
    FROM agg
) b
WHERE total_loss > 0
ORDER BY total_profit DESC
LIMIT 100
