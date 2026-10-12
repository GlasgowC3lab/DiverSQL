WITH agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        t.t_hour,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM
        store_sales ss
    JOIN
        store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN
        time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN
        customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate >= 500
        AND t.t_hour BETWEEN 12 AND 18
        AND s.s_state IN ('TN','LA')
        AND s.s_floor_space > 10000
    GROUP BY
        s.s_store_name,
        s.s_state,
        t.t_hour
    HAVING
        SUM(ss.ss_net_profit) > 10000
)
SELECT
    a.s_store_name,
    a.s_state,
    a.t_hour,
    a.sales_cnt,
    a.total_quantity,
    a.total_sales,
    a.total_profit,
    a.avg_net_paid,
    RANK() OVER (PARTITION BY a.s_state ORDER BY a.total_profit DESC) AS profit_rank_state
FROM agg a
ORDER BY a.s_state, profit_rank_state, a.total_profit DESC
LIMIT 20
