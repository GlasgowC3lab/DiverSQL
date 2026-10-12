WITH
    -- Base sales data
    sales AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_hdemo_sk,
            ss.ss_item_sk
        FROM store_sales ss
    ),
    -- Store returns data
    returns AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_amt,
            sr.sr_net_loss,
            sr.sr_hdemo_sk,
            sr.sr_item_sk
        FROM store_returns sr
    ),
    -- Web returns data (used for set operations)
    web AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_net_loss,
            wr.wr_refunded_hdemo_sk
        FROM web_returns wr
    ),
    -- Household demographics with income band
    demo_income AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            hd.hd_vehicle_count,
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    -- Date dimension (used for sales dates and catalog page dates)
    d_sales AS (
        SELECT d_date_sk, d_year, d_month_seq
        FROM date_dim
    ),
    -- Time dimension (used for sales times)
    t_sales AS (
        SELECT t_time_sk, t_hour
        FROM time_dim
    ),
    -- INTERSECT of store ticket numbers and web order numbers
    intersect_keys AS (
        SELECT ss_ticket_number AS key_val FROM sales
        INTERSECT
        SELECT wr_order_number FROM web
    ),
    -- EXCEPT of store ticket numbers that never appear in web orders
    except_keys AS (
        SELECT ss_ticket_number AS key_val FROM sales
        EXCEPT
        SELECT wr_order_number FROM web
    ),
    -- UNION of distinct buy potential values (deduped)
    union_buy_potential AS (
        SELECT hd_buy_potential FROM demo_income
        UNION
        SELECT hd_buy_potential FROM demo_income
    )
SELECT
    d.d_year,
    ib.ib_income_band_sk,
    di.hd_buy_potential,
    SUM(s.ss_ext_sales_price)                                 AS total_sales,
    SUM(COALESCE(r.sr_return_amt, 0))                         AS total_returns,
    SUM(s.ss_net_profit) - SUM(COALESCE(r.sr_net_loss, 0))    AS net_result,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(s.ss_ext_sales_price) DESC) AS sales_rank_year,
    COUNT(*) OVER ()                                          AS total_rows,
    (SELECT COUNT(*) FROM intersect_keys)                    AS intersect_count,
    (SELECT COUNT(*) FROM except_keys)                       AS except_count,
    (SELECT ARRAY_AGG(DISTINCT hp) FROM (SELECT hd_buy_potential AS hp FROM demo_income) t) AS distinct_buy_potentials
FROM sales s
JOIN returns r
     ON s.ss_ticket_number = r.sr_ticket_number
    AND s.ss_hdemo_sk = r.sr_hdemo_sk
JOIN demo_income di
     ON s.ss_hdemo_sk = di.hd_demo_sk
JOIN income_band ib
     ON di.ib_income_band_sk = ib.ib_income_band_sk
JOIN d_sales d
     ON s.ss_sold_date_sk = d.d_date_sk
JOIN t_sales t
     ON s.ss_sold_time_sk = t.t_time_sk
JOIN catalog_page cp
     ON cp.cp_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2000                     -- predicate 1
  AND di.hd_vehicle_count > 0                           -- predicate 2
  AND ib.ib_lower_bound >= 20000                         -- predicate 3
  AND s.ss_quantity > 1                                 -- predicate 4
GROUP BY ROLLUP (d.d_year, ib.ib_income_band_sk, di.hd_buy_potential)
ORDER BY d.d_year, total_sales DESC
LIMIT 100
