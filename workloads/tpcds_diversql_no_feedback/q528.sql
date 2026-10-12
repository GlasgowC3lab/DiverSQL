WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_warehouse_sk,
        wr.wr_return_amt,
        sm.sm_code,
        sm.sm_type,
        w.w_state,
        td.t_minute
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
)
SELECT *
FROM (
    SELECT
        cs_sold_date_sk AS date_sk,
        sm_code AS ship_code,
        w_state AS state,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(wr_return_amt) AS total_returns
    FROM base
    WHERE cs_quantity > 5
      AND sm_type = 'EXPRESS'
      AND t_minute = 14
      AND cs_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA')
      AND wr_return_amt > 100
    GROUP BY cs_sold_date_sk, sm_code, w_state

    UNION DISTINCT

    SELECT
        cs_sold_date_sk,
        sm_code,
        w_state,
        SUM(cs_ext_sales_price) * 0.9,
        SUM(wr_return_amt) * 1.1
    FROM base
    WHERE cs_quantity > 10
      AND sm_type = 'NEXT DAY'
      AND t_minute = 6
      AND cs_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'NY')
      AND wr_return_amt > 200
    GROUP BY cs_sold_date_sk, sm_code, w_state
) AS u
ORDER BY date_sk DESC, total_sales DESC
LIMIT 100
