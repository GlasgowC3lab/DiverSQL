WITH intersect_demo AS (
        SELECT ss_hdemo_sk AS demo_sk
        FROM store_sales
        WHERE ss_ext_tax > 15
        INTERSECT
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_vehicle_count > 1
    ),
    base AS (
        SELECT
            ss.ss_hdemo_sk,
            hd.hd_vehicle_count,
            ti.t_shift,
            ss.ss_net_profit,
            ss.ss_list_price,
            ss.ss_ext_tax,
            ss.ss_item_sk
        FROM store_sales ss
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN time_dim ti
            ON ss.ss_sold_time_sk = ti.t_time_sk
        WHERE ti.t_shift = 'first'
          AND ti.t_hour BETWEEN 8 AND 20
          AND hd.hd_buy_potential = '1001-5000'
          AND ss.ss_ext_tax > 5
          AND ss.ss_item_sk IN (SELECT ss_item_sk FROM store_sales WHERE ss_quantity >= 10)
          AND ss.ss_hdemo_sk IN (SELECT demo_sk FROM intersect_demo)
    ),
    agg1 AS (
        SELECT
            ss_hdemo_sk,
            hd_vehicle_count,
            t_shift,
            SUM(ss_net_profit) AS total_profit,
            AVG(ss_list_price) AS avg_list_price,
            COUNT(*) AS sales_cnt
        FROM base
        GROUP BY ss_hdemo_sk, hd_vehicle_count, t_shift
    ),
    ranked AS (
        SELECT
            ss_hdemo_sk,
            hd_vehicle_count,
            t_shift,
            total_profit,
            avg_list_price,
            sales_cnt,
            ROW_NUMBER() OVER (PARTITION BY t_shift ORDER BY total_profit DESC) AS rnk
        FROM agg1
    )
SELECT
    ss_hdemo_sk,
    hd_vehicle_count,
    t_shift,
    total_profit,
    avg_list_price,
    sales_cnt
FROM ranked
WHERE rnk <= 3
ORDER BY t_shift, rnk
