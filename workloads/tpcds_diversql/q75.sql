/* Goal: Rank customers by total profit and total sales within each year for United States warehouses, applying multiple filters and preserving unmatched web_sales or warehouse rows via a FULL OUTER JOIN. */
WITH ws_wh AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        w.w_warehouse_id,
        w.w_country,
        w.w_state
    FROM web_sales ws
    FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
agg AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_vehicle_count,
        sm.sm_type,
        ws_wh.w_country,
        SUM(ws_wh.ws_ext_sales_price) AS total_sales,
        SUM(ws_wh.ws_net_profit)      AS total_profit
    FROM ws_wh
    JOIN date_dim d
        ON ws_wh.ws_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ws_wh.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws_wh.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws_wh.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory i
        ON ws_wh.ws_warehouse_sk = i.inv_warehouse_sk
       AND ws_wh.ws_sold_date_sk = i.inv_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                                 -- predicate 1
      AND ws_wh.w_country = 'United States'                               -- predicate 2
      AND sm.sm_type IN ('REGULAR', 'OVERNIGHT')                         -- predicate 3
      AND c.c_birth_year BETWEEN 1960 AND 1980                            -- predicate 4
      AND hd.hd_vehicle_count >= 2                                        -- predicate 5
      AND i.inv_quantity_on_hand > 0                                      -- predicate 6
      AND ws_wh.ws_ext_sales_price > 1000                                 -- predicate 7
    GROUP BY
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_vehicle_count,
        sm.sm_type,
        ws_wh.w_country
)
SELECT
    d_year,
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_vehicle_count,
    sm_type,
    w_country,
    total_sales,
    total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
