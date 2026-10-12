WITH base AS (
    SELECT
        cs.cs_order_number AS order_number,
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        sm.sm_code AS ship_code,
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        td_sold.t_hour AS sold_hour,
        td_return.t_hour AS return_hour,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_profit AS net_profit,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td_sold ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim td_return ON sr.sr_return_time_sk = td_return.t_time_sk
    WHERE cp.cp_department = 'Electronics'
      AND sm.sm_code = 'AIR'
      AND td_sold.t_hour BETWEEN 8 AND 12
      AND td_return.t_hour BETWEEN 13 AND 17
      AND cs.cs_ext_tax > 20
      AND sr.sr_return_amt > 10
      AND c.c_birth_country = 'United States'
)
SELECT
    order_number,
    department,
    carrier,
    ship_code,
    customer_id,
    first_name,
    last_name,
    sold_hour,
    return_hour,
    ext_tax,
    net_profit,
    return_amt,
    net_loss,
    quantity,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY net_profit DESC) AS dept_profit_rn
FROM base
WHERE net_profit > 0
UNION
SELECT
    order_number,
    department,
    carrier,
    ship_code,
    customer_id,
    first_name,
    last_name,
    sold_hour,
    return_hour,
    ext_tax,
    net_profit,
    return_amt,
    net_loss,
    quantity,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY net_profit DESC) AS dept_profit_rn
FROM base
WHERE quantity >= 5
ORDER BY dept_profit_rn, net_profit DESC
LIMIT 100
